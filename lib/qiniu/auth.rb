# -*- encoding: utf-8 -*-
# vim: sw=2 ts=2

require 'date'
require 'openssl'
require 'uri'
require 'cgi'
require 'json'

require 'qiniu/exceptions'

module Qiniu
    module Auth
      DEFAULT_AUTH_SECONDS = 3600
      APPLICATION_FORM_URLENCODED = 'application/x-www-form-urlencoded'.freeze
      APPLICATION_JSON = 'application/json'.freeze
      AUTHORIZATION_PREFIX_QBOX = 'QBox '.freeze
      AUTHORIZATION_PREFIX_QINIU = 'Qiniu '.freeze

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
          :is_prefixal_scope      => "isPrefixalScope"     ,
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
          :fsize_min              => "fsizeMin"            ,
          :fsize_limit            => "fsizeLimit"          ,
          :detect_mime            => "detectMime"          ,
          :mime_limit             => "mimeLimit"           ,
          :uphosts                => "uphosts"             ,
          :global                 => "global"              ,
          :delete_after_days      => "deleteAfterDays"     ,
          :file_type              => "fileType"
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

        def generate_qbox_token_sign_with_mac(access_key, secret_key, url, body, content_type = APPLICATION_FORM_URLENCODED)
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
          # （仅限于content_type == "application/x-www-form-urlencoded"的情况）
          if body.is_a?(String) && !body.empty? && content_type == APPLICATION_FORM_URLENCODED
              signing_str += body
          end

          ### 生成数字签名
          sign = calculate_hmac_sha1_digest(secret_key, signing_str)
          return Utils.urlsafe_base64_encode(sign)
        end # generate_qbox_token_sign_with_mac
        alias :generate_acctoken_sign_with_mac :generate_qbox_token_sign_with_mac

        def generate_qiniu_token_sign_with_mac(access_key, secret_key, method, url, headers, body)
          ### 解析URL，生成待签名字符串
          uri = URI.parse(url)
          signing_str = "#{method.upcase} #{uri.path}"

          # 如有QueryString部分，则需要加上
          query_string = uri.query
          if query_string.is_a?(String) && !query_string.empty?
            signing_str += '?' + query_string
          end

          # 追加指定的 Headers
          signing_str += "\nHost: "
          signing_str += uri.host
          signing_str += ":#{uri.port}" if uri.port != uri.default_port
          signing_str += "\n"

          content_type = headers['Content-Type']
          if content_type.nil?
            content_type = APPLICATION_FORM_URLENCODED
            headers['Content-Type'] = content_type
          end
          signing_str += "Content-Type: #{content_type}\n"

          # 追加所有 X-Qiniu- 开头的 Headers
          x_qiniu_headers = []
          headers.each do |header_name, _|
            header_name = capitalize(header_name)
            if header_name.start_with?('X-Qiniu-') && header_name.length > 'X-Qiniu-'.length
              header_values = Array(headers[header_name])
              header_values.each do |header_value|
                x_qiniu_headers.push([header_name, header_value])
              end
            end
          end
          if !x_qiniu_headers.empty?
            x_qiniu_headers.sort!
            x_qiniu_headers.each do |header_name, header_value|
              signing_str += "#{header_name}: #{header_value}\n"
            end
          end

          # 追加换行符
          signing_str += "\n"

          # 如果有Body，则也加上
          # （仅限于content_type == "application/x-www-form-urlencoded" 或 content_type == "application/json"的情况）
          if body.is_a?(String) && !body.empty? && [APPLICATION_FORM_URLENCODED, APPLICATION_JSON].include?(content_type)
            signing_str += body
          end

          ### 生成数字签名
          sign = calculate_hmac_sha1_digest(secret_key, signing_str)
          return Utils.urlsafe_base64_encode(sign)
        end #generate_qiniu_token_sign_with_mac


        def generate_qbox_token(url, body = '', content_type = APPLICATION_FORM_URLENCODED)
          encoded_sign = generate_qbox_token_sign_with_mac(Config.settings[:access_key], Config.settings[:secret_key], url, body, content_type)
          return "#{Config.settings[:access_key]}:#{encoded_sign}"
        end # generate_qbox_token
        alias :generate_acctoken :generate_qbox_token # For compatibility

        def generate_qiniu_token(method, url, headers = {}, body = '', disable_qiniu_timestamp_signature: false)
          if !(disable_qiniu_timestamp_signature || disable_qiniu_timestamp_signature?) && headers['X-Qiniu-Date'].nil?
            headers['X-Qiniu-Date'] = x_qiniu_date
          end
          encoded_sign = generate_qiniu_token_sign_with_mac(Config.settings[:access_key], Config.settings[:secret_key], method, url, headers, body)
          return "#{Config.settings[:access_key]}:#{encoded_sign}"
        end # generate_qbox_token

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

        def decode_uptoken(uptoken)
          ### 解析uptoken
          uptoken_list = uptoken.split(":")
          raise BadUploadToken, uptoken if uptoken_list.length != 3

          ### 提取ak sign policy
          access_key = uptoken_list[0]
          sign = Utils.urlsafe_base64_decode(uptoken_list[1])
          str_policy = Utils.urlsafe_base64_decode(uptoken_list[2])
          hash_policy = JSON.parse(str_policy)
          ### 提取bucket
          bucket = hash_policy['scope'].split(":", 2)[0]
          ### 返回 ak sign policy bucket
          return  access_key, sign, hash_policy, bucket
        rescue
          raise BadUploadToken, uptoken
        end

        def _authenticate_callback_request(auth_str)
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

          encoded_sign = yield(access_key, secret_key)
          sign_pos = auth_str.index(encoded_sign, colon_pos + 1)
          !(sign_pos.nil? || (sign_pos + encoded_sign.length) != auth_str.length)
        end
        private :_authenticate_callback_request

        def authenticate_callback_request(auth_str, url, body = '', content_type = APPLICATION_FORM_URLENCODED)
          _authenticate_callback_request(auth_str) do |access_key, secret_key|
            generate_qbox_token_sign_with_mac(access_key, secret_key, url, body, content_type)
          end
        end # authenticate_callback_request

        def authenticate_callback_request_v2(auth_str, method, url, headers = {}, body = '')
          access_key = Config.settings[:access_key]
          secret_key = Config.settings[:secret_key]
          content_type = headers['Content-Type'] || APPLICATION_FORM_URLENCODED

          if auth_str.start_with?(AUTHORIZATION_PREFIX_QBOX)
            prefix_length = AUTHORIZATION_PREFIX_QBOX.length
            authenticate_callback_request(auth_str.slice(prefix_length..-1), url, body, content_type)
          elsif auth_str.start_with?(AUTHORIZATION_PREFIX_QINIU)
            _authenticate_callback_request(auth_str) do |access_key, secret_key|
              generate_qiniu_token_sign_with_mac(access_key, secret_key, method, url, headers, body)
            end
          else
            authenticate_callback_request(auth_str, url, body, content_type)
          end
        end

        def capitalize(name)
          name.to_s.split(/-/).map {|s| s.capitalize }.join('-')
        end
        private :capitalize

        DISABLE_QINIU_TIMESTAMP_SIGNATURE_ENV_KEY = "DISABLE_QINIU_TIMESTAMP_SIGNATURE".freeze

        def disable_qiniu_timestamp_signature?
          env = ENV[DISABLE_QINIU_TIMESTAMP_SIGNATURE_ENV_KEY]
          if env.nil?
            false
          else
            ['true', 'yes', 'y', '1'].include?(env.downcase)
          end
        end
        private :disable_qiniu_timestamp_signature?

        def x_qiniu_date
          DateTime.now.new_offset(0).strftime('%Y%m%dT%H%M%SZ')
        end
        private :x_qiniu_date
      end # class << self

    end # module Auth
end # module Qiniu
