# -*- encoding: utf-8 -*-

require 'zlib'
require 'yaml'
require 'tmpdir'
require 'fileutils'
require 'mime/types'
require 'digest/sha1'
require 'qiniu/rs/abstract'
require 'qiniu/rs/exceptions'
require 'qiniu/rs/io'

module Qiniu
  module RS
    module UP

      module AbstractClass
        class ChunkProgressNotifier
          include Qiniu::RS::Abstract
          abstract_methods :notify
          # def notify(block_index, block_put_progress); end
        end

        class BlockProgressNotifier
          include Qiniu::RS::Abstract
          abstract_methods :notify
          # def notify(block_index, checksum); end
        end
      end

      class ChunkProgressNotifier < AbstractClass::ChunkProgressNotifier
          def initialize(id)
              @data = UP::ProgressData.new(id)
          end
          def notify(index, progress)
              @data.set_progresses(index, progress)
              logmsg = "chunk #{progress[:offset]/Config.settings[:chunk_size]} in block #{index} successfully uploaded.\n" +
                       "{ctx:#{progress[:ctx]}, offset:#{progress[:offset]}, restsize:#{progress[:restsize]}, status_code:#{progress[:status_code]}}"
              Utils.debug(logmsg)
          end
      end

      class BlockProgressNotifier < AbstractClass::BlockProgressNotifier
          def initialize(id)
              @data = UP::ProgressData.new(id)
          end
          def notify(index, checksum)
              @data.set_checksums(index, checksum)
              Utils.debug "block #{index}: {checksum: #{checksum}} successfully uploaded."
          end
      end

      class ProgressData
          def initialize(id)
              @id = id
              @tmpdir = Config.settings[:tmpdir] + File::SEPARATOR + @id
              FileUtils.mkdir_p(@tmpdir) unless Dir.exists?(@tmpdir)
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
                  Utils.debug %Q(Updating tmpfile: #{@checksum_file})
              end
          end

          def set_progresses(index, progress)
              progresses = get_progresses
              progresses[index] = progress
              File.open(@progress_file, "w") do |f|
                  YAML::dump(progresses, f)
                  Utils.debug %Q(Updating tmpfile: #{@progress_file})
              end
          end

          def init_checksums(checksums)
              File.open(@checksum_file, "w") do |f|
                  YAML::dump(checksums, f)
                  Utils.debug %Q(Initializing tmpfile: #{@checksum_file})
              end
          end

          def init_progresses(progresses)
              File.open(@progress_file, "w") do |f|
                  YAML::dump(progresses, f)
                  Utils.debug %Q(Initializing tmpfile: #{@progress_file})
              end
          end

          def sweep!
              FileUtils.rm_r(@tmpdir)
          end
      end


      class << self
        include Utils

        def upload_with_token(uptoken,
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
            fsize = fh.data_size
            key = Digest::SHA1.hexdigest(local_file + fh.mtime.to_s) if key.nil?
            if mime_type.nil? || mime_type.empty?
              mime = MIME::Types.type_for local_file
              mime_type = mime.empty? ? 'application/octet-stream' : mime[0].content_type
            end
            if fsize > Config.settings[:block_size]
              code, data = _resumable_upload(uptoken, fh, fsize, bucket, key, mime_type, custom_meta, customer, callback_params)
            else
              code, data = IO.upload_with_token(uptoken, local_file, bucket, key, mime_type, custom_meta, callback_params, true)
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
            def path
                @fh.path
            end
            def mtime
                @fh.mtime
            end
            #delegate :path, :mtime, :to => :fh
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
            fpath = fh.path
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
                        raise FileSeekReadError.new(fpath, block_index, seek_pos, body_length, result_length)
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
                raise BlockSizeNotMathchError.new(fpath, block_index, progress[:offset], progress[:restsize], block_size)
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
                        raise FileSeekReadError.new(fpath, block_index, seek_pos, body_length, result_length)
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
            ((fsize + Config.settings[:block_size] - 1) / Config.settings[:block_size]).to_i
        end

        def _resumable_put(uptoken, fh, checksums, progresses, block_notifier = nil, chunk_notifier = nil)
            code, data = 0, {}
            fsize = fh.data_size
            block_count = _block_count(fsize)
            checksum_count = checksums.length
            progress_count = progresses.length
            if checksum_count != block_count || progress_count != block_count
                raise BlockCountNotMathchError.new(fh.path, block_count, checksum_count, progress_count)
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
          path = '/rs-mkfile/' + Utils.urlsafe_base64_encode(entry_uri) + "/fsize/#{fsize}"
          path += '/mimeType/' + Utils.urlsafe_base64_encode(mime_type) if !mime_type.nil? && !mime_type.empty?
          path += '/meta/' + Utils.urlsafe_base64_encode(custom_meta) if !custom_meta.nil? && !custom_meta.empty?
          path += '/customer/' + customer if !customer.nil? && !customer.empty?
          callback_query_string = Utils.generate_query_string(callback_params) if !callback_params.nil? && !callback_params.empty?
          path += '/params/' + Utils.urlsafe_base64_encode(callback_query_string) if !callback_query_string.nil? && !callback_query_string.empty?
          url = Config.settings[:up_host] + path
          body = ''
          checksums.each do |checksum|
              body += Utils.urlsafe_base64_decode(checksum)
          end
          _call_binary_with_token(uptoken, url, body)
        end

        def _resumable_upload(uptoken, fh, fsize, bucket, key, mime_type = nil, custom_meta = nil, customer = nil, callback_params = nil)
          block_count = _block_count(fsize)
          progress_data = ProgressData.new(key)
          checksums = progress_data.get_checksums
          progresses = progress_data.get_progresses
          if checksums.empty?
              block_count.times{checksums << ''}
              progress_data.init_checksums(checksums)
          end
          if progresses.empty?
              block_count.times{progresses << _new_block_put_progress_data}
              progress_data.init_progresses(progresses)
          end
          chunk_notifier = ChunkProgressNotifier.new(key)
          block_notifier = BlockProgressNotifier.new(key)
          code, data = _resumable_put(uptoken, fh, checksums, progresses, block_notifier, chunk_notifier)
          if Utils.is_response_ok?(code)
            entry_uri = bucket + ':' + key
            code, data = _mkfile(uptoken, entry_uri, fsize, checksums, mime_type, custom_meta, customer, callback_params)
          end
          if Utils.is_response_ok?(code)
            Utils.debug "File #{fh.path} {size: #{fsize}} successfully uploaded."
            progress_data.sweep!
          end
          [code, data]
        end

      end
    end
  end
end
