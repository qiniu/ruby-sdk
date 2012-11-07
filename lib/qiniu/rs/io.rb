# -*- encoding: utf-8 -*-

require 'mime/types'
require 'digest/sha1'
require 'qiniu/rs/exceptions'

module Qiniu
  module RS
    module IO
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
    end
  end
end
