# -*- encoding: utf-8 -*-

module Qiniu
  module Storage
    class << self
      include Utils

      def upload_with_token(uptoken,
                            local_file,
                            bucket,
                            key = nil,
                            mime_type = nil,
                            custom_meta = nil,
                            callback_params = nil,
                            enable_crc32_check = false,
                            rotate = nil)
        action_params = _generate_action_params(
          local_file,
          bucket,
          key,
          mime_type,
          custom_meta,
          enable_crc32_check,
          rotate
        )

        if callback_params.nil?
          callback_params = {:bucket => bucket, :key => key, :mime_type => mime_type}
        end
        callback_query_string = Utils.generate_query_string(callback_params)
        url = Config.settings[:up_host] + '/upload'

        Utils.upload_multipart_data(url, local_file, action_params, callback_query_string, uptoken)
      end # upload_with_token

      def upload_with_token_2(uptoken,
                              local_file,
                              key = nil,
                              x_vars = nil)
        ### 构造URL
        url = Config.settings[:up_host]
        url[/\/*$/] = ''
        url += '/'

        ### 构造HTTP Body
        post_data = {
          :file      => File.new(local_file, 'rb'),
          :multipart => true,
        }
        if not uptoken.nil?
          post_data[:token] = uptoken
        end
        if not key.nil?
          post_data[:key] = key
        end
        if x_vars.is_a?(Hash)
          post_data.merge!(x_vars)
        end

        ### 发送请求
        Utils.http_request url, post_data
      end # upload_with_token_2

      private
      def _generate_action_params(local_file,
                                  bucket,
                                  key = nil,
                                  mime_type = nil,
                                  custom_meta = nil,
                                  enable_crc32_check = false,
                                  rotate = nil)
        raise NoSuchFileError, local_file unless File.exist?(local_file)

        if key.nil?
          key = Digest::SHA1.hexdigest(local_file + Time.now.to_s)
        end

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
      end # _generate_action_params

    end # class << self
  end # module Storage
end # module Qiniu
