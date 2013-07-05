# -*- encoding: utf-8 -*-

require 'json'
require 'qiniu/tokens/access_token'
require 'qiniu/rs/utils'

module Qiniu
  module RS
 
=begin
      class UploadToken < AccessToken

        include Utils

        attr_accessor :scope, :expires_in, :callback_url, :callback_body_type, :customer, :escape, :async_options, :return_body

        def initialize(opts = {})
          @scope = opts[:scope]
          @expires_in = opts[:expires_in] || 3600
          @callback_url = opts[:callback_url]
          @callback_body_type = opts[:callback_body_type]
          @customer = opts[:customer]
          @escape = opts[:escape]
          @async_options = opts[:async_options]
          @return_body = opts[:return_body]
        end

        def generate_signature
          params = {:scope => @scope, :deadline => Time.now.to_i + @expires_in}
          params[:callbackUrl] = @callback_url if !@callback_url.nil? && !@callback_url.empty?
          params[:callbackBodyType] = @callback_body_type if !@callback_body_type.nil? && !@callback_body_type.empty?
          params[:customer] = @customer if !@customer.nil? && !@customer.empty?
          params[:escape] = 1 if @escape == 1 || @escape == true
          params[:asyncOps] = @async_options if !@async_options.nil? && !@async_options.empty?
          params[:returnBody] = @return_body if !@return_body.nil? && !@return_body.empty?
          Utils.urlsafe_base64_encode(params.to_json)
        end

        def generate_token
          signature = generate_signature
          encoded_digest = generate_encoded_digest(signature)
          %Q(#{@access_key}:#{encoded_digest}:#{signature})
        end

      end
=end


      class PutPolicy

        include Utils

        attr_accessor :scope, :callback_url, :callback_body, :return_url, :return_body, :async_ops, :end_user, :expires

        def initialize(opts = {})
          @scope = opts[:scope]
          @callback_url = opts[:callback_url]
          @callback_body = opts[:callback_body]
          @return_url = opts[:return_url]
          @return_body = opts[:return_body]
          @async_ops = opts[:async_ops]
          @end_user = opts[:end_user]
          @expires = opts[:expires] || 3600
        end

        def token(mac = nil)
          if mac == nil then
            mac = Mac.New()
            mac.access_key = Config.settings[:access_key]
            mac.secret_key = Config.settings[:secret_key]
            if mac.access_key.nil? || mac.access_key.empty? ||
              mac.secret_key.nil? || mac.secret_key.empty? then
              raise "Invalid Access Key or Secret Key"
            end
          end

          policy_json = marshal_policy()
          token = mac.generate_encoded_digest(policy_json)
          return mac.access_key + ":" + token + ":" + policy_json
        end

        def marshal_policy
          params = {:scope => @scope, :deadline => Time.now.to_i + @expires}
          params[:callbackUrl] = @callback_url if !@callback_url.nil? && !@callback_url.empty?
          params[:callbackBody] = @callback_body if !@callback_body.nil? && !@callback_body.empty?
          params[:returnUrl] = @return_url if !@return_url.nil? && !@return.empty?
          params[:returnBody] = @return_body if !@return_body.nil? && !@return_body.empty?
          params[:asyncOps] = @async_ops if !@async_ops.nil? && !@async_ops.empty?
          params[:endUser] = 1 if @escape == 1 || @escape == true
          return Utils.urlsafe_base64_encode(params.to_json)
        end

      end
  end
end
