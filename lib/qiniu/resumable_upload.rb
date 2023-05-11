# -*- encoding: utf-8 -*-

require 'zlib'
require 'yaml'
require 'tmpdir'
require 'fileutils'
require 'mime/types'
require 'digest/sha1'
require 'qiniu/abstract'
require 'qiniu/exceptions'
require 'json'

module Qiniu
    module Storage

      module AbstractClass
        class ChunkProgressNotifier
          include Qiniu::Abstract
          abstract_methods :notify
          # def notify(block_index, block_put_progress); end
        end

        class BlockProgressNotifier
          include Qiniu::Abstract
          abstract_methods :notify
          # def notify(block_index, checksum); end
        end
      end # module AbstractClass

      class ChunkProgressNotifier < AbstractClass::ChunkProgressNotifier
          def notify(index, progress)
              logmsg = "chunk #{progress['offset']/Config.settings[:chunk_size]} in block #{index} successfully uploaded.\n" + progress.to_s
              Utils.debug(logmsg)
          end
      end # class ChunkProgressNotifier

      class BlockProgressNotifier < AbstractClass::BlockProgressNotifier
          def notify(index, checksum)
              Utils.debug "block #{index}: {ctx: #{checksum}} successfully uploaded."
              Utils.debug "block #{index}: {checksum: #{checksum}} successfully uploaded."
          end
      end # class BlockProgressNotifier

      class << self
        include Utils

        def resumable_upload_with_token(uptoken,
                              local_file,
                              bucket,
                              key = nil,
                              mime_type = nil,
                              custom_meta = nil,
                              customer = nil,
                              callback_params = nil,
                              rotate = nil,
                              resume_record_file = nil,
                              version = :v1,
                              part_size = Config.settings[:block_size])
          File.open(local_file, 'rb') do |ifile|
            fh = FileData.new(ifile)
            fsize = fh.data_size
            key = Digest::SHA1.hexdigest(local_file + fh.mtime.to_s) if key.nil?
            if mime_type.nil? || mime_type.empty?
              mime_type = MIME::Types.type_for(local_file).first || 'application/octet-stream'
            end
            code, data = _resumable_upload(uptoken, fh, fsize, bucket, key, mime_type.to_s, custom_meta, customer, callback_params, rotate, resume_record_file, version, part_size)
            [code, data]
          end
        end # resumable_upload_with_token

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
        end # class FileData

        def _new_block_put_progress_data
          {'ctx' => nil, 'offset' => 0, 'restsize' => nil, 'status_code' => nil, 'host' => nil}
        end # _new_block_put_progress_data

        def _new_block_put_progress_data_v2
          {'etag' => nil, 'offset' => 0, 'restsize' => nil, 'partNumber' => 0, 'status_code' => nil, 'host' => nil}
        end

        def _record_upload_progress
          {'ctx' => nil, 'offset' => 0, 'upload_extra' => {}}
        end

        def get_upload_record(resume_record_file)
          JSON.load(File.read(resume_record_file))
        rescue
          nil
        end

        def _call_binary_with_token(uptoken, url, data, content_type = nil, retry_times = 0)
          options = {
              :headers => {
                  :content_type   => 'application/octet-stream',
                  'Authorization' => 'UpToken ' + uptoken
              }
          }
          if content_type && !content_type.empty? then
              options[:headers][:content_type] = content_type
          end

          code, data, raw_headers = HTTP.api_post(url, data, options)
          unless HTTP.is_response_ok?(code)
              retry_times += 1
              if Config.settings[:auto_reconnect] && retry_times < Config.settings[:max_retry_times]
                  return _call_binary_with_token(uptoken, url, data, options[:content_type], retry_times)
              end
          end
          return code, data, raw_headers
        end # _call_binary_with_token

        def _mkblock(bucket, uptoken, block_size, body)
            url = Config.up_host(bucket) + "/mkblk/#{block_size}"
            _call_binary_with_token(uptoken, url, body)
        end # _mkblock

        def _putblock(uphost, uptoken, ctx, offset, body)
            url = uphost + "/bput/#{ctx}/#{offset}"
            _call_binary_with_token(uptoken, url, body)
        end # _putblock

        def _resumable_put_block(bucket,
                                 uptoken,
                                 fh,
                                 block_index,
                                 block_size,
                                 chunk_size,
                                 progress,
                                 retry_times,
                                 notifier)
            code, data = 0, {}
            fpath = fh.path
            # this block has never been uploaded.
            if progress['ctx'].nil? || progress['ctx'].empty?
                progress['offset'] = 0
                progress['restsize'] = block_size
                # choose the smaller one
                body_length = [block_size, chunk_size].min
                for i in 1..retry_times
                    seek_pos = block_index * Config.settings[:block_size]
                    body = fh.get_data(seek_pos, body_length)
                    result_length = body.length
                    if result_length != body_length
                        raise FileSeekReadError.new(fpath, block_index, seek_pos, body_length, result_length)
                    end

                    code, data, raw_headers = _mkblock(bucket, uptoken, block_size, body)
                    Utils.debug "Mkblk : #{code.inspect} #{data.inspect} #{raw_headers.inspect}"

                    body_crc32 = Zlib.crc32(body)
                    if HTTP.is_response_ok?(code) && data["crc32"] == body_crc32
                        progress['ctx'] = data["ctx"]
                        progress['offset'] = body_length
                        progress['restsize'] = block_size - body_length
                        progress['status_code'] = code
                        progress['host'] = data["host"]
                        if notifier && notifier.respond_to?("notify")
                            notifier.notify(block_index, progress)
                        end
                        break
                    elsif i == retry_times && data["crc32"] != body_crc32
                        Log.logger.error %Q(Uploading block error. Expected crc32: #{body_crc32}, but got: #{data["crc32"]})
                        return code, data, raw_headers
                    end
                end
            elsif progress['offset'] + progress['restsize'] != block_size
                raise BlockSizeNotMathchError.new(fpath, block_index, progress['offset'], progress['restsize'], block_size)
            end

            # loop uploading other chunks except the first one
            while progress['restsize'] > 0 && progress['restsize'] < block_size
                # choose the smaller one
                body_length = [progress['restsize'], chunk_size].min
                for i in 1..retry_times
                    seek_pos = block_index*Config.settings[:block_size] + progress['offset']
                    body = fh.get_data(seek_pos, body_length)
                    result_length = body.length
                    if result_length != body_length
                        raise FileSeekReadError.new(fpath, block_index, seek_pos, body_length, result_length)
                    end

                    code, data, raw_headers = _putblock(progress['host'], uptoken, progress['ctx'], progress['offset'], body)
                    Utils.debug "Bput : #{code.inspect} #{data.inspect} #{raw_headers.inspect}"

                    body_crc32 = Zlib.crc32(body)
                    if HTTP.is_response_ok?(code) && data["crc32"] == body_crc32
                        progress['ctx'] = data["ctx"]
                        progress['offset'] += body_length
                        progress['restsize'] -= body_length
                        progress['status_code'] = code
                        progress['host'] = data["host"]
                        if notifier && notifier.respond_to?("notify")
                            notifier.notify(block_index, progress)
                        end
                        break
                    elsif i == retry_times && data["crc32"] != body_crc32
                        Log.logger.error %Q(Uploading block error. Expected crc32: #{body_crc32}, but got: #{data["crc32"]})
                        return code, data, raw_headers
                    end
                end
            end
            # return
            return code, data, raw_headers
        end # _resumable_put_block

        def _resumeble_put_block_v2(bucket,
                                    uptoken,
                                    fh,
                                    block_index,
                                    progress,
                                    retry_times,
                                    notifier,
                                    part_size,
                                    upload_extra,
                                    restsize)
          fpath = fh.path
          if restsize > part_size
            for i in 1..retry_times
              seek_positon = block_index * part_size
              body = fh.get_data(seek_positon, part_size)
              if body.length != part_size
                raise FileSeekReadError.new(fpath, block_index, seek_positon, body.length, body.length)
              end
              body_md5 = Digest::MD5.hexdigest(body)
              code, data, raw_headers = _upload_part(upload_extra['host'], uptoken, body, bucket, block_index + 1, upload_extra['upload_id'], upload_extra['encoded_object_name'])

              if HTTP.is_response_ok?(code) && data["md5"] == body_md5
                progress['etag'] = data["etag"]
                progress['offset'] = seek_positon
                progress['restsize'] = restsize - part_size * block_index
                progress['status_code'] = code
                progress['host'] = data["host"]
                if notifier && notifier.respond_to?("notify")
                  notifier.notify(block_index, progress)
                end
                break
              elsif i == retry_times && data["md5"] != body_md5
                Log.logger.error %Q(Uploading block error. Expected md5: #{body_md5}, but got: #{data["md5"]})
                break
              end
            end
          else
            for i in 1..retry_times
              seek_positon = block_index * part_size
              body = fh.get_data(seek_positon, restsize)
              if body.length != restsize
                raise FileSeekReadError.new(fpath, block_index, seek_positon, body.length, body.length)
              end
              body_md5 = Digest::MD5.hexdigest(body)
              code, data, raw_headers = _upload_part(upload_extra['host'], uptoken, body, bucket, block_index + 1, upload_extra['upload_id'], upload_extra['encoded_object_name'])

              if HTTP.is_response_ok?(code) && data["md5"] == body_md5
                progress['etag'] = data["etag"]
                progress['offset'] = seek_positon
                progress['restsize'] = restsize - part_size
                progress['status_code'] = code
                progress['host'] = data["host"]
                if notifier && notifier.respond_to?("notify")
                  notifier.notify(block_index, progress)
                end
                break
              elsif i == retry_times && data["md5"] != body_md5
                Log.logger.error %Q(Uploading block error. Expected md5: #{body_md5}, but got: #{data["md5"]})
                break
              end
            end
          end
          return code, data, raw_headers
        end

        def _block_count(fsize)
            ((fsize + Config.settings[:block_size] - 1) / Config.settings[:block_size]).to_i
        end # _block_count

        def _resumable_put(bucket,
                           uptoken,
                           fh,
                           checksums,
                           progresses,
                           block_notifier = nil,
                           chunk_notifier = nil,
                           complete_block = nil,
                           version = :v1,
                           part_size = Config.settings[:block_size],
                           upload_record = nil,
                           resume_record_file = null)

            upload_extra = upload_record['upload_extra']
            code, data = 0, {}
            fsize = fh.data_size
            block_count = _block_count(fsize)
            progress_count = progresses.length
            if progress_count != block_count
              checksums = []
              progresses = []
              complete_block = 0
            end
            complete_block.upto(block_count-1).each do |block_index|
                if checksums[block_index].nil? || checksums[block_index].empty?
                    block_size = part_size
                    if block_index == block_count - 1
                        block_size = fsize - block_index * part_size
                    end
                    if version == :v1
                      progresses[block_index] ||= _new_block_put_progress_data
                    else
                      progresses[block_index] ||= _new_block_put_progress_data_v2
                    end
                    if version == :v1
                      code, data = _resumable_put_block(bucket, uptoken, fh, block_index, block_size, Config.settings[:chunk_size], progresses[block_index], Config.settings[:max_retry_times], chunk_notifier)
                    else
                      restsize = fsize - part_size * block_index
                      code, data = _resumeble_put_block_v2(bucket, uptoken, fh, block_index, progresses[block_index], Config.settings[:max_retry_times], chunk_notifier, part_size, upload_extra, restsize)
                    end
                    if HTTP.is_response_ok?(code)
                        if version == :v1
                          checksums[block_index] = data["ctx"]
                        else
                          checksums[block_index] = {'etag' => data["etag"], 'partNumber' => block_index + 1}
                        end
                        upload_record['ctx'] = checksums
                        if resume_record_file && !resume_record_file.empty?
                          File.write(resume_record_file, upload_record.to_json)
                        end

                        if block_notifier && block_notifier.respond_to?("notify")
                            block_notifier.notify(block_index, checksums[block_index])
                        end
                    end
                end
            end
            return [code, data]
        end # _resumable_put

        def _mkfile(uphost,
                    uptoken,
                    entry_uri,
                    fsize,
                    checksums,
                    mime_type = nil,
                    custom_meta = nil,
                    customer = nil,
                    callback_params = nil,
                    rotate = nil)
          path = '/rs-mkfile/' + Utils.urlsafe_base64_encode(entry_uri) + "/fsize/#{fsize}"
          path += '/mimeType/' + Utils.urlsafe_base64_encode(mime_type) if mime_type && !mime_type.empty?
          path += '/meta/' + Utils.urlsafe_base64_encode(custom_meta) if custom_meta && !custom_meta.empty?
          path += '/customer/' + customer if customer && !customer.empty?
          callback_query_string = HTTP.generate_query_string(callback_params) if callback_params && !callback_params.empty?
          path += '/params/' + Utils.urlsafe_base64_encode(callback_query_string) if callback_query_string && !callback_query_string.empty?
          path += '/rotate/' + rotate if rotate && rotate.to_i >= 0
          url = uphost + path
          body = checksums.join(',')
          _call_binary_with_token(uptoken, url, body, 'text/plain')
        end # _mkfile

        def _resumable_upload(uptoken,
                              fh,
                              fsize,
                              bucket,
                              key,
                              mime_type = nil,
                              custom_meta = nil,
                              customer = nil,
                              callback_params = nil,
                              rotate = nil,
                              resume_record_file = nil,
                              version = :v1,
                              part_size = Config.settings[:block_size])

          if part_size.nil?
            part_size = Config.settings[:block_size]
          end
          upload_extra = {}
          host = Config.up_host(bucket)
          upload_extra['host'] = host
          if version == :v2
            encoded_object_name = _encode_object_name(key)
            upload_extra['encoded_object_name'] = encoded_object_name
          end
          block_count = _block_count(fsize)

          chunk_notifier = ChunkProgressNotifier.new()
          block_notifier = BlockProgressNotifier.new()

          progresses = []
          checksums = []
          complete_block = 0
          upload_record = _record_upload_progress
          record = get_upload_record(resume_record_file) if resume_record_file

          if record.nil?
            upload_record['upload_extra'] = upload_extra
            if version == :v1
              progresses = block_count.times.map { _new_block_put_progress_data }
            else
              data = _init_req(host, encoded_object_name, bucket, uptoken)
              upload_extra['upload_id'] = data['uploadId']
              upload_extra['expired'] = data['expireAt']
              progresses = block_count.times.map { _new_block_put_progress_data_v2 }
            end
          else
            ctx = record['ctx']
            complete_block = ctx.length
            if version == :v1
              upload_record = record
              checksums = upload_record['ctx']
              progresses = block_count.times.map { _new_block_put_progress_data }
            elsif version == :v2
              extra = record['upload_extra']
              if extra['upload_id'] && extra['expired'] > Time.now.to_i
                upload_extra = extra
                upload_record = record
                checksums = upload_record['ctx']
                progresses = block_count.times.map { _new_block_put_progress_data_v2 }
              else
                data = _init_req(host,encoded_object_name, bucket, uptoken)
                upload_extra['upload_id'] = data['uploadId']
                upload_extra['expired'] = data['expireAt']
                upload_record['upload_extra'] = extra
                progresses = block_count.times.map { _new_block_put_progress_data_v2 }
              end
            else
              Log.logger.error 'only support :v1 / :v2 now!'
            end
          end

          code, data, raw_headers = _resumable_put(bucket, uptoken, fh, checksums, progresses, block_notifier, chunk_notifier, complete_block, version, part_size, upload_record, resume_record_file)
          FileUtils.rm_f(resume_record_file) if resume_record_file

          if HTTP.is_response_ok?(code)
            uphost = data["host"]
            if version == :v1
              entry_uri = bucket + ':' + key
              code, data, raw_headers = _mkfile(uphost, uptoken, entry_uri, fsize, checksums, mime_type, custom_meta, customer, callback_params, rotate)
              Utils.debug "Mkfile : #{code.inspect} #{data.inspect} #{raw_headers.inspect}"
            else
              code, data, raw_headers = _complete_parts(key, uptoken, upload_extra, bucket, checksums, mime_type, customer)
            end
          end

          if HTTP.is_response_ok?(code)
            Utils.debug "File #{fh.path} {size: #{fsize}} successfully uploaded."
          end

          return code, data, raw_headers
        end # _resumable_upload

        def _init_req(host,
                      encoded_object_name,
                      bucket,
                      uptoken)

          url = host + '/buckets/' + bucket + '/objects/' + encoded_object_name + '/uploads'
          options = {
            :headers => {
              :content_type   => 'application/json',
              'Authorization' => 'UpToken ' + uptoken
            }
          }
          _, body, _ = HTTP.api_post(url, '', options)
          return body
        end # init request

        def  _upload_part(host,
                          uptoken,
                          block,
                          bucket,
                          part_number,
                          upload_id,
                          encoded_object_name)

          options = {
            :headers => {
              'Authorization' => 'UpToken ' + uptoken,
              'Content-Type' => 'application/octet-stream',
              'Content-MD5' => Digest::MD5.hexdigest(block)
            }
          }
          url = "#{host}/buckets/#{bucket}/objects/#{encoded_object_name}/uploads/#{upload_id}/#{part_number}"
          code, body, raw_headers = HTTP.api_put(url, block, options)
          return code, body, raw_headers
        end # upload block

        def _complete_parts(fname,
                            uptoken,
                            upload_extra,
                            bucket,
                            etags,
                            mime_type = nil,
                            customer = nil)
          options = {
            :headers => {
              'Authorization' => 'UpToken ' + uptoken,
              'Content-Type' => 'application/json'
            }
          }
          body = {
            'fname' => fname,
            'mimeType' => mime_type,
            'customVars' => customer,
            'parts' => etags
          }
          json_body = body.to_json
          url = "#{upload_extra["host"]}/buckets/#{bucket}/objects/#{upload_extra["encoded_object_name"]}/uploads/#{upload_extra["upload_id"]}"
          code, data, raw_headers = HTTP.api_post(url, json_body, options)
          return code, data, raw_headers
        end #coplete upload

        def _encode_object_name(key)
          return '~' if key.nil?
          Utils.urlsafe_base64_encode(key)
        end
      end # self class
    end # module Storage
end # module Qiniu
