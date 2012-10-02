# -*- encoding: utf-8 -*-

require 'zlib'
require 'yaml'
require 'tmpdir'
require 'mime/types'
require 'digest/sha1'
require 'qiniu/rs/abstract'
require 'qiniu/rs/exceptions'

module Qiniu
  module RS
    module UP

      module Abstract
        class ChunkProgressNotifier
          include Abstract
          abstract_methods :notify
          # def notify(block_index, block_put_progress); end
        end

        class BlockProgressNotifier
          include Abstract
          abstract_methods :notify
          # def notify(block_index, checksum); end
        end
      end

      class ChunkProgressNotifier < Abstract::ChunkProgressNotifier
          def initialize(id)
              @data = ProgressData.new(id)
          end
          def notify(index, progress)
              @data.set_progresses(index, progress)
              logmsg = "chunk #{index} successfully uploaded.\n"
                     + "{ctx:#{progress[:ctx]}, offset:#{progress[:offset]}, restsize:#{progress[:restsize]}, status_code:#{progress[:status_code]}}"
              Log.logger.info logmsg
          end
      end

      class BlockProgressNotifier < Abstract::BlockProgressNotifier
          def initialize(id)
              @data = ProgressData.new(id)
          end
          def notify(index, checksum)
              @data.set_checksums(index, checksum)
              logmsg = "block #{index}:#{checksum} successfully uploaded."
              Log.logger.info logmsg
          end
      end


      class << self
        include Utils

        def upload(uptoken,
                   local_file,
                   bucket,
                   key = nil,
                   mime_type = nil,
                   custom_meta = nil,
                   customer = nil,
                   callback_params = nil)
          raise NoSuchFileError, local_file unless File.exist?(local_file)
          begin
              ifile = File.open(local_file, 'rb')
              fh = FileData.new(ifile)
              key = Digest::SHA1.hexdigest(local_file + fh.mtime.to_s) if key.nil?
              entry_uri = bucket + ':' + key
              if mime_type.nil? || mime_type.empty?
                mime = MIME::Types.type_for local_file
                mime_type = mime.empty? ? 'application/octet-stream' : mime[0].content_type
              end
              fsize = fh.data_size
              block_count = _block_count(fsize)
              progress_data = ProgressData.new(key)
              checksums = progress_data.get_checksums
              progresses = progress_data.get_progresses
              block_count.times{checksums << ''} if checksums.empty?
              block_count.times{progresses << _new_block_put_progress_data} if progresses.empty?
              chunk_notifier = ChunkProgressNotifier.new(key)
              block_notifier = BlockProgressNotifier.new(key)
              code, data = _resumable_put(uptoken, fh, checksums, progresses, block_notifier, chunk_notifier)
              if Utils.is_response_ok?(code)
                  code, data = _mkfile(uptoken, entry_uri, fsize, checksums, mime_type, custom_meta, customer, callback_params)
              end
              if Utils.is_response_ok?(code)
                  Log.logger.info "File #{local_file} successfully uploaded."
              #    progress_data.sweep!
              end
              [code, data]
          ensure
            ifile.close unless ifile.nil?
          end
        end

        private

        class FileData
            attr_accessor :fh
            def initialize(fh)
                @fh = fh
            end
            def data_size
                @fh.stat.size
            end
            def get_data(offset, length)
                @fh.seek(offset)
                @fh.read(length)
            end
            delegate :mtime, :to => :fh
        end

        class ProgressData
          def initialize(id)
              @id = id
              @tmpdir = Config.settings[:tmpdir] + File::SEPARATOR + @id
              Dir.mkdir(@tmpdir) unless Dir.exists?(@tmpdir)
              @checksum_file = @tmpdir + File::SEPARATOR + 'checksums'
              @progress_file = @tmpdir + File::SEPARATOR + 'progresses'
          end

          def get_checksums
              File.exist?(@checksum_file) ? YAML.load_file(@checksum_file) : []
          end

          def get_progresses
              File.exist?(@progress_file) ? YAML.load_file(@progress_file) : []
          end

          def set_checksums(index, checksum)
              checksums = get_checksums
              checksums[index] = checksum
              File.open(@checksum_file, "w") do |f|
                  YAML::dump(checksums, f)
              end
          end

          def set_progresses(index, progress)
              progresses = get_progresses
              progresses[index] = progress
              File.open(@progress_file, "w") do |f|
                  YAML::dump(progresses, f)
              end
          end

          def sweep!
              Dir.rmdir(@tmpdir)
          end
        end

        def _new_block_put_progress_data
          {:ctx => nil, :offset => 0, :restsize => nil, :status_code => nil}
        end

        def _call_binary_with_token(uptoken, url, data, retry_times = 0)
          options = {
              :method => :post,
              :content_type => 'application/octet-stream',
              :upload_signature_token => uptoken
          }
          code, data = http_request url, data, options
          unless Utils.is_response_ok?(code)
              retry_times += 1
              if Config.settings[:auto_reconnect] && retry_times < Config.settings[:max_retry_times]
                  return _call_binary_with_token(uptoken, url, data, retry_times)
              end
          end
          [code, data]
        end

        def _mkblock(uptoken, block_size, body)
            url = Config.settings[:up_host] + "/mkblk/#{block_size}"
            _call_binary_with_token(uptoken, url, body)
        end

        def _putblock(uptoken, ctx, offset, body)
            url = Config.settings[:up_host] + "/bput/#{ctx}/#{offset}"
            _call_binary_with_token(uptoken, url, body)
        end

        def _resumable_put_block(uptoken, fh, block_index, block_size, chunk_size, progress, retry_times = 1, notifier)
            code, data = 0, {}
            # this block has never been uploaded.
            if progress[:ctx] == nil || progress[:ctx].empty?
                progress[:offset] = 0
                progress[:restsize] = block_size
                # choose the smaller one
                body_length = [block_size, chunk_size].min
                for i in 1..retry_times
                    seek_pos = block_index*Config.settings[:block_size]
                    body = fh.get_data(seek_pos, body_length)
                    result_length = body.length
                    if result_length != body_length
                        raise FileSeekReadError.new(seek_pos, body_length, result_length)
                    end
                    code, data = _mkblock(uptoken, block_size, body)
                    body_crc32 = Zlib.crc32(body)
                    if Utils.is_response_ok?(code) && data["crc32"] == body_crc32
                        progress[:ctx] = data["ctx"]
                        progress[:offset] = body_length
                        progress[:restsize] = block_size - body_length
                        progress[:status_code] = code
                        if !notifier.nil? && notifier.respond_to?("notify")
                            notifier.notify(block_index, progress)
                        end
                        break
                    elsif i == retry_times && data["crc32"] != body_crc32
                        Log.logger.error %Q(Uploading block error. Expected crc32: #{body_crc32}, but got: #{data["crc32"]})
                    end
                end
            elsif progress[:offset] + progress[:restsize] != block_size
                raise ResumablePutBlockError.new("Invalid arg. File length does not match.")
            end
            # loop uploading other chunks except the first one
            while progress[:restsize].to_i > 0 && progress[:restsize] < block_size
                # choose the smaller one
                body_length = [progress[:restsize], chunk_size].min
                for i in 1..retry_times
                    seek_pos = block_index*Config.settings[:block_size] + progress[:offset]
                    body = fh.get_data(seek_pos, body_length)
                    result_length = body.length
                    if result_length != body_length
                        raise FileSeekReadError.new(seek_pos, body_length, result_length)
                    end
                    code, data = _putblock(uptoken, progress[:ctx], progress[:offset], body)
                    body_crc32 = Zlib.crc32(body)
                    if Utils.is_response_ok?(code) && data["crc32"] == body_crc32
                        progress[:ctx] = data["ctx"]
                        progress[:offset] += body_length
                        progress[:restsize] -= body_length
                        progress[:status_code] = code
                        if !notifier.nil? && notifier.respond_to?("notify")
                            notifier.notify(block_index, progress)
                        end
                        break
                    elsif i == retry_times && data["crc32"] != body_crc32
                        Log.logger.error %Q(Uploading block error. Expected crc32: #{body_crc32}, but got: #{data["crc32"]})
                    end
                end
            end
            # return
            return [code, data]
        end

        def _block_count(fsize)
            ((fsize + Config.block_size - 1) / Config.block_size).to_i
        end

        def _resumable_put(uptoken, fh, checksums, progresses, block_notifier = nil, chunk_notifier = nil)
            code, data = 0, {}
            block_count = _block_count(fh.data_size)
            if checksums.length != block_count || progresses.length != block_count
                raise ResumablePutError.new("Invalid arg. Unexpected block count.")
            end
            0.upto(block_count-1).each do |block_index|
                if checksums[block_index].nil? || checksums[block_index].empty?
                    block_size = Config.settings[:block_size]
                    if block_index == block_count - 1
                        block_size = fsize - block_index*Config.settings[:block_size]
                    end
                    if progresses[block_index].nil?
                        progresses[block_index] = _new_block_put_progress_data
                    end
                    code, data = _resumable_put_block(uptoken, fh, block_index, block_size, Config.settings[:chunk_size], progresses[block_index], Config.settings[:max_retry_times], chunk_notifier)
                    if Utils.is_response_ok?(code)
                        checksums[block_index] = data["checksum"]
                        if !block_notifier.nil? && block_notifier.respond_to?("notify")
                            block_notifier.notify(block_index, checksums[block_index])
                        end
                    end
                end
            end
            return [code, data]
        end

        def _mkfile(uptoken, entry_uri, fsize, checksums, mime_type = nil, custom_meta = nil, customer = nil, callback_params = nil)
          path = '/rs-mkfile/' + Utils.urlsafe_base64_encode(entry_uri) + '/fsize/' + fsize
          path += '/mimeType/' + Utils.urlsafe_base64_encode(mime_type) if !mime_type.nil? && !mime_type.empty?
          path += '/meta/' + Utils.urlsafe_base64_encode(custom_meta) if !custom_meta.nil? && !custom_meta.empty?
          path += '/customer/' + customer if !customer.nil? && !customer.empty?
          path += '/params/' + Utils.urlsafe_base64_encode(callback_params) if !callback_params.nil? && !callback_params.empty?
          url = Config.settings[:up_host] + path
          body = ''
          checksums.each do |checksum|
              body += Utils.urlsafe_base64_decode(checksum)
          end
          _call_binary_with_token(uptoken, url, body)
        end

      end
    end
  end
end
