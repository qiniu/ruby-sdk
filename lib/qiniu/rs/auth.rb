# -*- encoding: utf-8 -*-

require 'qiniu/rs/exceptions'

module Qiniu
  module RS
    module Auth
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
          reset_token(data["access_token"], data["refresh_token"]) if code == 200
          [code, data]
        end

        def exchange_by_refresh_token!(refresh_token)
          post_data = {
            :client_id     => Config.settings[:client_id],
            :grant_type    => "refresh_token",
            :refresh_token => refresh_token
          }
          code, data = http_request Config.settings[:auth_url], post_data
          reset_token(data["access_token"], data["refresh_token"]) if code == 200
          [code, data]
        end

        def reset_token(access_token, refresh_token)
          @access_token  = access_token
          @refresh_token = refresh_token
        end

        def call_with_logged_in(url, data, retry_times = 0)
          raise MissingAccessToken if @access_token.nil?
          code, data = http_request url, data, {:access_token => @access_token}
          if code == 401
            raise MissingRefreshToken if @refresh_token.nil?
            code, data = exchange_by_refresh_token!(@refresh_token)
            if code == 401
              raise MissingUsernameOrPassword if (@username.nil? || @password.nil?)
              code, data = exchange_by_password!(@username, @password)
            end
            if code == 200
              retry_times += 1
              if Config.settings[:auto_reconnect] && retry_times < Config.settings[:max_retry_times]
                return call_with_logged_in(url, data, retry_times)
              end
            end
          end
          [code, data]
        end

        def call_with_signature(url, data, retry_times = 0)
          code, data = http_request url, data, {:signature_auth => true}
          [code, data]
        end

        def request(url, data = nil)
          begin
            if Config.settings[:access_key].empty? || Config.settings[:secret_key].empty?
              code, data = Auth.call_with_logged_in(url, data)
            else
              code, data = Auth.call_with_signature(url, data)
            end
          rescue [MissingAccessToken, MissingRefreshToken, MissingUsernameOrPassword] => e
            Log.logger.error e
            code, data = 401, {}
          end
          [code, data]
        end

      end
    end
  end
end
