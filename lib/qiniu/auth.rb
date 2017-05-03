# -*- encoding: utf-8 -*-
# vim: sw=2 ts=2

require 'openssl'
require 'uri'
require 'cgi'

require 'qiniu/exceptions'

module Qiniu
    module Auth
      DEFAULT_AUTH_SECONDS = 3600

      class << self
        def calculate_deadline(expires_in, deadline = nil)
          ### 授权期计算
          if expires_in.is_a?(Integer) && expires_in > 0 then
            # 指定相对时间，单位：秒
            return Time.now.to_i + expires_in
          elsif deadline.is_a?(Integer) then
            # 指定绝对时间，常用于调试和单元测试
            return deadline
          end

          # 默认授权期1小时
          return Time.now.to_i + DEFAULT_AUTH_SECONDS
        end # calculate_deadline

        def calculate_hmac_sha1_digest(sk, str)
          raise ArgumentError, "Please set Qiniu's access_key and secret_key before authorize any tokens." if sk.nil?
          OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), sk, str)
        end
      end # class << self

      class PutPolicy
        private
        def initialize(bucket,
                       key = nil,
                       expires_in = DEFAULT_AUTH_SECONDS,
                       deadline = nil)
          ### 设定scope参数（必填项目）
          self.scope!(bucket, key)

          ### 设定deadline参数（必填项目）
          @expires_in = expires_in
          @deadline   = Auth.calculate_deadline(expires_in, deadline)
        end # initialize

        PARAMS = {
          # 字符串类型参数
          :scope                  => "scope"               ,
          :save_key               => "saveKey"             ,
          :end_user               => "endUser"             ,
          :return_url             => "returnUrl"           ,
          :return_body            => "returnBody"          ,
          :callback_url           => "callbackUrl"         ,
          :callback_host          => "callbackHost"        ,
          :callback_body          => "callbackBody"        ,
          :callback_body_type     => "callbackBodyType"    ,
          :persistent_ops         => "persistentOps"       ,
          :persistent_notify_url  => "persistentNotifyUrl" ,
          :persistent_pipeline    => "persistentPipeline"  ,

          # 数值类型参数
          :deadline               => "deadline"            ,
          :insert_only            => "insertOnly"          ,
          :fsize_limit            => "fsizeLimit"          ,
          :callback_fetch_key     => "callbackFetchKey"    ,
          :detect_mime            => "detectMime"          ,
          :mime_limit             => "mimeLimit"           ,
          :uphosts                => "uphosts"             ,
          :global                 => "global"              ,
          :delete_after_days      => "deleteAfterDays"
        } # PARAMS

        public
        attr_reader :bucket, :key

        def scope!(bucket, key = nil)
          @bucket = bucket
          @key    = key

          if key.nil? then
            # 新增语义，文件已存在则失败
            @scope = bucket
          else
            # 覆盖语义，文件已存在则直接覆盖
            @scope = "#{bucket}:#{key}"
          end

          if Config.settings[:multi_region]
            begin
              @uphosts = Config.host_manager.up_hosts(bucket)
              @global = Config.host_manager.global(bucket)
            rescue
              # Do nothing
            end
          end
        end # scope!

        def expires_in!(seconds)
          if !seconds.nil? then
            return @expires_in
          end

          @epires_in = seconds
          @deadline  = Auth.calculate_deadline(seconds)

          return @expires_in
        end # expires_in!

        def expires_in=(seconds)
          return expires_in!(seconds)
        end # expires_in=

        def expires_in
          return @expires_in
        end # expires_in

        def allow_mime_list! (list)
          @mime_limit = list
        end # allow_mime_list!

        def deny_mime_list! (list)
          @mime_limit = "!#{list}"
        end # deny_mime_list!

        def insert_only!
          @insert_only = 1
        end # insert_only!

        def detect_mime!
          @detect_mime = 1
        end # detect_mime!

        def to_json
          args = {}

          PARAMS.each_pair do |key, fld|
            val = self.__send__(key)
            if !val.nil? then
              args[fld] = val
            end
          end

          return args.to_json
        end # to_json

        PARAMS.each_pair do |key, fld|
          attr_accessor key
        end
      end # class PutPolicy

      class << self
        EMPTY_ARGS = {}

        ### 生成下载授权URL
        def authorize_download_url(url, args = EMPTY_ARGS)
          ### 提取AK/SK信息
          access_key = Config.settings[:access_key]
          secret_key = Config.settings[:secret_key]

          download_url = url

          ### URL变换：追加FOP指令
          if args[:fop].is_a?(String) && args[:fop] != '' then
            if download_url.include?('?')
              # 已有参数
              download_url = "#{download_url}&#{args[:fop]}"
            else
              # 尚无参数
              download_url = "#{download_url}?#{args[:fop]}"
            end
          end

          ### 授权期计算
          e = Auth.calculate_deadline(args[:expires_in], args[:deadline])

          ### URL变换：追加授权期参数
          if download_url.include?('?')
            # 已有参数
            download_url = "#{download_url}&e=#{e}"
          else
            # 尚无参数
            download_url = "#{download_url}?e=#{e}"
          end

          ### 生成数字签名
          sign = calculate_hmac_sha1_digest(secret_key, download_url)
          encoded_sign = Utils.urlsafe_base64_encode(sign)

          ### 生成下载授权凭证
          dntoken = "#{access_key}:#{encoded_sign}"

          ### 返回下载授权URL
          return "#{download_url}&token=#{dntoken}"
        end # authorize_download_url

        ### 对包含中文或其它 utf-8 字符的 Key 做下载授权
        def authorize_download_url_2(domain, key, args = EMPTY_ARGS)
          url_encoded_key = CGI::escape(key)

          schema = args[:schema] || "http"
          port   = args[:port]

          if port.nil? then
            download_url = "#{schema}://#{domain}/#{url_encoded_key}"
          else
            download_url = "#{schema}://#{domain}:#{port}/#{url_encoded_key}"
          end
          return authorize_download_url(download_url, args)
        end # authorize_download_url_2

        def generate_acctoken_sign_with_mac(access_key, secret_key, url, body)
          ### 解析URL，生成待签名字符串
          uri = URI.parse(url)
          signing_str = uri.path

          # 如有QueryString部分，则需要加上
          query_string = uri.query
          if query_string.is_a?(String) && !query_string.empty?
            signing_str += '?' + query_string
          end

          # 追加换行符
          signing_str += "\n"

          # 如果有Body，则也加上
          # （仅限于mime == "application/x-www-form-urlencoded"的情况）
          if body.is_a?(String) && !body.empty?
              signing_str += body
          end

          ### 生成数字签名
          sign = calculate_hmac_sha1_digest(secret_key, signing_str)
          return Utils.urlsafe_base64_encode(sign)
        end # generate_acctoken_sign_with_mac

        def generate_acctoken(url, body = '')
          encoded_sign = generate_acctoken_sign_with_mac(Config.settings[:access_key], Config.settings[:secret_key], url, body)
          return "#{Config.settings[:access_key]}:#{encoded_sign}"
        end # generate_acctoken

        def generate_uptoken(put_policy)
          ### 提取AK/SK信息
          access_key = Config.settings[:access_key]
          secret_key = Config.settings[:secret_key]

          ### 生成待签名字符串
          encoded_put_policy = Utils.urlsafe_base64_encode(put_policy.to_json)

          ### 生成数字签名
          sign = calculate_hmac_sha1_digest(secret_key, encoded_put_policy)
          encoded_sign = Utils.urlsafe_base64_encode(sign)

          ### 生成上传授权凭证
          uptoken = "#{access_key}:#{encoded_sign}:#{encoded_put_policy}"

          ### 返回上传授权凭证
          return uptoken
        end # generate_uptoken

        def authenticate_callback_request(auth_str, url, body = '')
          ### 提取AK/SK信息
          access_key = Config.settings[:access_key]
          secret_key = Config.settings[:secret_key]

          ### 检查签名格式
          ak_pos = auth_str.index(access_key)
          if ak_pos.nil? then
            return false
          end

          colon_pos = auth_str.index(':', ak_pos + 1)
          if colon_pos.nil? || ((ak_pos + access_key.length) != colon_pos) then
            return false
          end

          encoded_sign = generate_acctoken_sign_with_mac(access_key, secret_key, url, body)
          sign_pos = auth_str.index(encoded_sign, colon_pos + 1)
          if sign_pos.nil? || ((sign_pos + encoded_sign.length) != auth_str.length) then
            return false
          end

          return true
        end # authenticate_callback_request
      end # class << self

    end # module Auth
end # module Qiniu
