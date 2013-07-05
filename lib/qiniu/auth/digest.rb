# -*- encoding: utf-8 -*-

require 'qiniu/rs/exceptions'
require 'qiniu/rpc'
require 'URI'

module Qiniu
  module Auth
    module Digest

      class << self
        # make_base_url(): construct url with domain & key
        def make_base_url(domain, key)
          return "http://" + domain + "/" + URI.escape(key)
        end
      end

      # class Mac: hold access key & secret key
      class Mac

        include Utils

        def initiailze(accesskey, secretkey)
          @access_key = accesskey
          @secret_key = secretkey
        end

        def sign_it(data)
          hmac = HMAC::SHA1.new(@secret_key)
          hmac.update(data)
          return urlsafe_base64_encode(hmac.digest)
        end

        private :sign_it

        def sign(data)
          return %Q(#{@access_key}:#{sign_it(data)})
        end

        def sign_with_data(data)
          data64 = urlsafe_base64_encode(data)
          return %Q(#{@access_key}:#{sign_it(data)}:#{data64})
        end

        def generate_access_token(path, query, body)
          access = path
          access += '?' + query if !query.nil? && !query.empty?
          access += "\n";
          access += body
          return %Q(#{@access_key}:#{sign_it(access)})
        end

      end

      class Client < RPC.Client

        include Utils

        attr_accessor :mac

        def initialize(host, mac = nil)
          super(host)
          if mac.nil? then
            @mac = Mac.new(Config.settings[:access_key], Config.settings[:secret_key])
          else
            @mac = mac
          end
        end        
      end

      class PutClient < Client

        include Utils

        def initialize(host, mac = nil)
          super(host, mac)
        end

        # 执行put操作，调用post_mulitpart()
        # 参数：
        #   1. fields：放入multipart的字段
        def call(fields)
          post_mulitpart("", mp_fields)
        end
      end

      class ManageClient < Client

        include Utils

        def initialize(host, mac = nil)
          super(host, mac)
        end

        # 执行management操作，包括生成AccessToken，构造form body等
        # 参数：
        #   1. path：操作构成的路径。
        #   2. body：管理操作的body（操作的集合）。
        def call(path, query, body)
          token = @mac.generate_access_token(path, query, ops)

          post(path + "?" + query, body, { "Content-Type" => "application/x-www-form-urlencoded", 
            "Authorization" => "Qbox " + token })
        end

      end
    end
  end
end






=begin
      class << self
        include Utils

        def exchange_by_password!(username, password)
          @username = username
          @password = password
          post_data = {
            :client_id  => Config.settings[:client_id],
            :grant_type => "password",
            :username   => username,
            :password   => password
          }
          code, data = http_request Config.settings[:auth_url], post_data
          reset_token(data["access_token"], data["refresh_token"]) if Utils.is_response_ok?(code)
          [code, data]
        end

        def exchange_by_refresh_token!(refresh_token)
          post_data = {
            :client_id     => Config.settings[:client_id],
            :grant_type    => "refresh_token",
            :refresh_token => refresh_token
          }
          code, data = http_request Config.settings[:auth_url], post_data
          reset_token(data["access_token"], data["refresh_token"]) if Utils.is_response_ok?(code)
          [code, data]
        end

        def reset_token(access_token, refresh_token)
          @access_token  = access_token
          @refresh_token = refresh_token
        end

        def call_with_signature(url, data, retry_times = 0, options = {}, token = nil)
          if token.nil? then
            code, data = http_request url, data, options.merge({:qbox_signature_token => generate_qbox_signature(url, data)})
          else
            code, data = http_request url, data, options.merge({:qbox_signature_token => token})
          end
          [code, data]
        end

        def request_access_token(mac, url, data = nil, options = {})
          if mac.access_key.empty? || mac.secret_key.empty? then
            raise "Invalid Access Key or Secret Key"
          end

          begin
            code, data = http_request(url, data, 0
              , options.merge({:qbox_signature_token => mac.generate_access_token()}))
          rescue MissingAccessToken => e
            Log.logger.error e
            code, data = 401, {}
          rescue MissingRefreshToken => e
            Log.logger.error e
            code, data = 401, {}
          rescue MissingUsernameOrPassword => e
            Log.logger.error e
            code, data = 401, {}
          end
          [code, data]
        end

      end
=end

    end
  end
end
