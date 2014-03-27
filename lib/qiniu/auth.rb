# -*- encoding: utf-8 -*-
# vim: sw=2 ts=2

require 'hmac-sha1'
require 'uri'

require 'qiniu/exceptions'

module Qiniu
    module Auth

      class << self

        include Utils

        def call_with_signature(url, data, retry_times = 0, options = {})
          return Utils.http_request(
            url,
            data,
            options.merge({:qbox_signature_token => generate_acctoken(url, data)})
          )
        end # call_with_signature

        def request(url, data = nil, options = {})
          code, data, raw_headers = Auth.call_with_signature(url, data, 0, options)
          [code, data, raw_headers]
        end # request

        EMPTY_ARGS = {}

        ### 生成下载授权URL
        def authorize_download_url(url, args = EMPTY_ARGS)
          ### 提取AK/SK信息
          access_key = Config.settings[:access_key]
          secret_key = Config.settings[:secret_key]

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

          ### 返回下载授权URL
          return "#{download_url}&token=#{dntoken}"
        end # authorize_download_url

        def generate_acctoken(url, body = '')
          ### 提取AK/SK信息
          access_key = Config.settings[:access_key]
          secret_key = Config.settings[:secret_key]

          ### 解析URL，生成待签名字符串
          uri = URI.parse(url)
          signing_str = uri.path

          # 如有QueryString部分，则需要加上
          query_string = uri.query
          if query_string.is_a?(String) && !query_string.empty?
            singin_str += '?' + query_string
          end

          # 追加换行符
          signing_str += "\n"

          # 如果有Body，则也加上
          # （仅限于mime == "application/x-www-form-urlencoded"的情况）
          if body.is_a?(String) && !body.empty?
              signing_str += body 
          end

          ### 生成数字签名
          sign = HMAC::SHA1.new(secret_key).update(signing_str).digest
          encoded_sign = Utils.urlsafe_base64_encode(sign)

          ### 生成管理授权凭证
          acctoken = "#{access_key}:#{encoded_sign}"

          ### 返回管理授权凭证
          return acctoken
        end # generate_acctoken

      end # class << self

    end # module Auth
end # module Qiniu
