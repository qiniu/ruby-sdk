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

        def put_file(url, local_file, bucket = nil, key = nil, mime_type = nil, custom_meta = nil, callback_params = nil, enable_crc32_check = false)
          raise NoSuchFileError, local_file unless File.exist?(local_file)
          key = Digest::SHA1.hexdigest(local_file + Time.now.to_s) if key.nil?
          entry_uri = bucket + ':' + key
          if mime_type.nil?
            mime = MIME::Types.type_for local_file
            mime_type = mime.empty? ? 'application/octet-stream' : mime[0].content_type
          end
          action_params = '/rs-put/' + Utils.urlsafe_base64_encode(entry_uri) + '/mimeType/' + Utils.urlsafe_base64_encode(mime_type)
          action_params += '/meta/' + Utils.urlsafe_base64_encode(custom_meta) unless custom_meta.nil?
          action_params += '/crc32/' + Utils.crc32checksum(local_file).to_s if enable_crc32_check
          callback_params = {:bucket => bucket, :key => key, :mime_type => mime_type} if callback_params.nil?
          callback_query_string = Utils.generate_query_string(callback_params)
          Utils.upload_multipart_data(url, local_file, action_params, callback_query_string)
        end

      end
    end
  end
end
