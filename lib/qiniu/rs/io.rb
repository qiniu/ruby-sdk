# -*- encoding: utf-8 -*-

require 'mime/types'
require 'digest/sha1'
require 'qiniu/rs/exceptions'
require 'qiniu/auth/digest'

module Qiniu
  module RS
    module IO

```
      class << self
        include Utils

        def put_auth(expires_in = nil, callback_url = nil)
          url = Config.settings[:io_host] + "/put-auth/"
          url += "#{expires_in}" if !expires_in.nil? && expires_in > 0
          if !callback_url.nil? && !callback_url.empty?
            encoded_callback_url = Utils.urlsafe_base64_encode(callback_url)
            url += "/callback/#{encoded_callback_url}"
          end
          Auth.request(url)
        end

        def upload_file(url, local_file, bucket, key = nil, mime_type = nil, custom_meta = nil, callback_params = nil, enable_crc32_check = false)
          action_params = _generate_action_params(local_file, bucket, key, mime_type, custom_meta, enable_crc32_check)
          callback_params = {:bucket => bucket, :key => key, :mime_type => mime_type} if callback_params.nil?
          callback_query_string = Utils.generate_query_string(callback_params)
          Utils.upload_multipart_data(url, local_file, action_params, callback_query_string)
        end

        def put_file(local_file, bucket, key = nil, mime_type = nil, custom_meta = nil, enable_crc32_check = false)
          action_params = _generate_action_params(local_file, bucket, key, mime_type, custom_meta, enable_crc32_check)
          url = Config.settings[:io_host] + action_params
          options = {:content_type => 'application/octet-stream'}
          Auth.request url, ::IO.read(local_file), options
        end

        def upload_with_token(uptoken, local_file, bucket, key = nil, mime_type = nil, custom_meta = nil, callback_params = nil, enable_crc32_check = false, rotate = nil)
          action_params = _generate_action_params(local_file, bucket, key, mime_type, custom_meta, enable_crc32_check, rotate)
          callback_params = {:bucket => bucket, :key => key, :mime_type => mime_type} if callback_params.nil?
          callback_query_string = Utils.generate_query_string(callback_params)
          url = Config.settings[:up_host] + '/upload'
          Utils.upload_multipart_data(url, local_file, action_params, callback_query_string, uptoken)
        end

        private
        def _generate_action_params(local_file, bucket, key = nil, mime_type = nil, custom_meta = nil, enable_crc32_check = false, rotate = nil)
          raise NoSuchFileError, local_file unless File.exist?(local_file)
          key = Digest::SHA1.hexdigest(local_file + Time.now.to_s) if key.nil?
          entry_uri = bucket + ':' + key
          if mime_type.nil? || mime_type.empty?
            mime = MIME::Types.type_for local_file
            mime_type = mime.empty? ? 'application/octet-stream' : mime[0].content_type
          end
          action_params = '/rs-put/' + Utils.urlsafe_base64_encode(entry_uri) + '/mimeType/' + Utils.urlsafe_base64_encode(mime_type)
          action_params += '/meta/' + Utils.urlsafe_base64_encode(custom_meta) unless custom_meta.nil?
          action_params += '/crc32/' + Utils.crc32checksum(local_file).to_s if enable_crc32_check
          action_params += '/rotate/' + rotate if !rotate.nil? && rotate.to_i >= 0
          action_params
        end

      end
```

      class PutExtra

        attr_accessor :Params, :MimeType, :Crc32, :CheckCrc

        def initialize
          @Params = {}          #用户自定义参数，{"x:<name>" => <value>}，参数名以x:开头
          @MimeType = ''
          @Crc32 = 0
          @CheckCrc = 0
      end

      class PutRet

        attr_accessor :Hash, :Key

      end

      class << self

        include Utils

        #上传文件对象：
        # 参数：
        #   1. uptoken：upload token
        #   2. key：待上传的key
        #   3. data：上传的数据，需要File对象
        #   4. extra：PutExtra对象，包含用户自定义参数
        def Put(uptoken, key, data, extra = nil)
          if extra.nil? then
            extra = PutExtra.new()
          end

          fields = {}

          if extra.CheckCrc != 0 then
            fields.merge({ :crc32 => extra.Crc32 })
          end

          if !key.nil? then
            fields.merge({ :key => key })
          end

          if data.nil? then
            raise "Invalid 'data' parameter. "
          end

          fields.merge({ :file => data })

          if token.nil? then
            raise "Invalid parameter 'put_policy'."
          end

          fields.merge(extra.Params)

          return digest.PutClient.new(Config.settings[:up_host]).call(fields)
        end

        def PutFile(uptoken, key, localfile, extra)
          if extra.CheckCrc == 1 then
            extra.Crc32 = crc32checksum(localfile)
          end

          data = File.new(localfile, 'rb')
          return Put(uptoken, key, data, extra)
        end

      end

    end
  end
end
