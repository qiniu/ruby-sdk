# -*- encoding: utf-8 -*-
# vim: sw=2 ts=2

require 'stringio'

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
        callback_query_string = HTTP.generate_query_string(callback_params)

        url = Config.up_host(bucket) + '/upload'
        post_data = {
          :params     => callback_query_string,
          :action     => action_params,
          :file       => File.new(local_file, 'rb'),
          :multipart  => true
        }
        if !uptoken.nil? then
          post_data[:auth] = uptoken unless uptoken.nil?
        end

        return HTTP.api_post(url, post_data)
      end # upload_with_token

      def upload_with_token_2(uptoken,
                              local_file,
                              key = nil,
                              x_vars = nil,
                              opts = {})
        ### 构造URL
        _, _, _, bucket = Auth.decode_uptoken(uptoken)
        url = Config.up_host(bucket)
        url[/\/*$/] = ''
        url += '/'

        ### 构造HTTP Body
        file = File.new(local_file, 'rb')
        if not opts[:content_type].nil?
          file.define_singleton_method("content_type") do
            opts[:content_type]
          end
        end

        post_data = {
          :file      => file,
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
        HTTP.api_post(url, post_data)
      end # upload_with_token_2

      def upload_buffer_with_token(uptoken,
                              buf,
                              key = nil,
                              x_vars = nil,
                              opts = {})
        ### 构造 URL
        _, _, _, bucket = Auth.decode_uptoken(uptoken)
        url = Config.up_host(bucket)
        url[/\/*$/] = ''
        url += '/'

        ### 构造 HTTP Body
        if buf.is_a?(String)
          data = StringIO.new(buf)
        elsif buf.respond_to?(:read)
          data = buf
        end

        data.define_singleton_method("path") do
          'NO-PATH'
        end
        data.define_singleton_method("original_filename") do
          'A-MASS-OF-DATA'
        end
        data.define_singleton_method("content_type") do
          (opts[:content_type].nil? || opts[:content_type].empty?) ? 'application/octet-stream' : opts[:content_type]
        end

        post_data = {
          :file      => data,
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
        HTTP.api_post(url, post_data)
      rescue BucketIsMissing
        raise 'upload_buffer_with_token requires :bucket option when multi_region is enabled'
      end # upload_with_token_2

      ### 授权举例
      # put_policy.bucket | put_policy.key | key     | 语义 | 授权
      # :---------------- | :------------- | :------ | :--- | :---
      # trivial_bucket    | <nil>          | <nil>   | 新增 | 允许，最终key为1)使用put_policy.save_key生成的值或2)资源内容的Hash值
      # trivial_bucket    | <nil>          | foo.txt | 新增 | 允许
      # trivial_bucket    | <nil>          | bar.jpg | 新增 | 允许
      # trivial_bucket    | foo.txt        | <nil>   | 覆盖 | 允许，由SDK将put_policy.key赋值给key实现
      # trivial_bucket    | foo.txt        | foo.txt | 覆盖 | 允许
      # trivial_bucket    | foo.txt        | bar.jpg | 覆盖 | 禁止，put_policy.key与key不一致
      def upload_with_put_policy(put_policy,
                                 local_file,
                                 key = nil,
                                 x_vars = nil,
                                 opts = {})
        uptoken = Auth.generate_uptoken(put_policy)
        if key.nil? then
          key = put_policy.key
        end

        return upload_with_token_2(uptoken, local_file, key, x_vars, opts)
      rescue BucketIsMissing
        raise 'upload_with_put_policy requires :bucket option when multi_region is enabled'
      end # upload_with_put_policy

      def upload_buffer_with_put_policy(put_policy,
                                 buf,
                                 key = nil,
                                 x_vars = nil,
                                 opts = {})
        uptoken = Auth.generate_uptoken(put_policy)
        if key.nil? then
          key = put_policy.key
        end

        return upload_buffer_with_token(uptoken, buf, key, x_vars, opts)
      rescue BucketIsMissing
        raise 'upload_buffer_with_put_policy requires :bucket option when multi_region is enabled'
      end # upload_buffer_with_put_policy

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
