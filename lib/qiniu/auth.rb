# -*- encoding: utf-8 -*-

require 'hmac-sha1'

require 'qiniu/exceptions'

module Qiniu
    module Auth

      class << self

        include Utils

        def call_with_signature(url, data, retry_times = 0, options = {})
          code, data, raw_headers = http_request url, data, options.merge({:qbox_signature_token => generate_qbox_signature(url, data, options[:mime])})
          [code, data, raw_headers]
        end # call_with_signature

        def request(url, data = nil, options = {})
          code, data, raw_headers = Auth.call_with_signature(url, data, 0, options)
          [code, data, raw_headers]
        end # request

        EMPTY_ARGS = {}

        ### 生成下载授权URL
        def authorize_download_url(url, args = EMPTY_ARGS)
          ### 提取AK/SK信息
          access_key = args[:access_key]
          if access_key.nil? then
            access_key = Config.settings[:access_key]
          end

          secret_key = args[:secret_key]
          if secret_key.nil? then
            secret_key = Config.settings[:secret_key]
          end

          ### 授权期计算
          if args[:expires].is_a?(Integer) && args[:expires] > 0 then
            # 指定相对时间，单位：秒
            e = Time.now.to_i + args[:expires]
          elsif args[:deadline].is_a?(Integer) then
            # 指定绝对时间，常用于调试和单元测试
            e = args[:deadline]
          else
            # 默认授权期1小时
            e = Time.now.to_i + 3600
          end

          ### URL变换：追加授权期参数
          if url.index('?').is_a?(Fixnum) then
            # 已有参数
            download_url = "#{url}&e=#{e}"
          else
            # 尚无参数
            download_url = "#{url}?e=#{e}"
          end

          ### 生成数字签名
          sign = HMAC::SHA1.new(secret_key).update(download_url).digest
          encoded_sign = Utils.urlsafe_base64_encode(sign)

          ### 生成下载授权凭证
          dntoken = "#{access_key}:#{encoded_sign}"

          ### 返回下载授权URL及相关参数
          return "#{download_url}&token=#{dntoken}", e, dntoken
        end # authorize_download_url

      end # class << self

    end # module Auth
end # module Qiniu
