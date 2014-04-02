# -*- encoding: utf-8 -*-
# vim: sw=2 ts=2

require 'hmac-sha1'
require 'uri'

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
          :callback_body          => "callbackBody"        ,
          :persistent_ops         => "persistentOps"       ,
          :persistent_notify_url  => "persistentNotifyUrl" ,
          :transform              => "transform"           ,

          # 数值类型参数
          :deadline               => "deadline"            ,
          :insert_only            => "insertOnly"          ,
          :fsize_limit            => "fsizeLimit"          ,
          :detect_mime            => "detectMime"          ,
          :mime_limit             => "mimeLimit"           ,
          :fop_timeout            => "fopTimeout"
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
          e = Auth.calculate_deadline(args[:expires_in], args[:deadline])

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
          sign = HMAC::SHA1.new(secret_key).update(signing_str).digest
          encoded_sign = Utils.urlsafe_base64_encode(sign)

          ### 生成管理授权凭证
          acctoken = "#{access_key}:#{encoded_sign}"

          ### 返回管理授权凭证
          return acctoken
        end # generate_acctoken

        def generate_uptoken(put_policy)
          ### 提取AK/SK信息
          access_key = Config.settings[:access_key]
          secret_key = Config.settings[:secret_key]

          ### 生成待签名字符串
          encoded_put_policy = Utils.urlsafe_base64_encode(put_policy.to_json)

          ### 生成数字签名
          sign = HMAC::SHA1.new(secret_key).update(encoded_put_policy).digest
          encoded_sign = Utils.urlsafe_base64_encode(sign)

          ### 生成上传授权凭证
          uptoken = "#{access_key}:#{encoded_sign}:#{encoded_put_policy}"

          ### 返回上传授权凭证
          return uptoken
        end # generate_uptoken
      end # class << self

    end # module Auth
end # module Qiniu
