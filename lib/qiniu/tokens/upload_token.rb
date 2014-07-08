# -*- encoding: utf-8 -*-

require 'json'
require 'qiniu/tokens/access_token'
require 'qiniu/utils'

### UploadToken 类已经过时，请改用 Qiniu::Auth.generate_uptoken 方法 ###

module Qiniu
      class UploadToken < AccessToken

        include Utils

        attr_accessor :scope, :expires_in, :callback_url, :callback_body, :callback_body_type, :customer, :escape, :async_options, :return_body, :return_url

        def initialize(opts = {})
          @scope = opts[:scope]
          @expires_in = opts[:expires_in] || 3600
          @callback_url = opts[:callback_url]
          @callback_body = opts[:callback_body]
          @callback_body_type = opts[:callback_body_type]
          @customer = opts[:customer]
          @escape = opts[:escape]
          @async_options = opts[:async_options]
          @return_body = opts[:return_body]
          @return_url = opts[:return_url]
        end

        def generate_signature
          params = {:scope => @scope, :deadline => Time.now.to_i + @expires_in}
          params[:callbackUrl] = @callback_url if !@callback_url.nil? && !@callback_url.empty?
          params[:callbackBody] = @callback_body if !@callback_body.nil? && !@callback_body.empty?
          params[:callbackBodyType] = @callback_body_type if !@callback_body_type.nil? && !@callback_body_type.empty?
          params[:customer] = @customer if !@customer.nil? && !@customer.empty?
          params[:escape] = 1 if @escape == 1 || @escape == true
          params[:asyncOps] = @async_options if !@async_options.nil? && !@async_options.empty?
          params[:returnBody] = @return_body if !@return_body.nil? && !@return_body.empty?
          params[:returnUrl] = @return_url if !@return_url.nil? && !@return_url.empty?
          Utils.urlsafe_base64_encode(params.to_json)
        end

        def generate_token
          signature = generate_signature
          encoded_digest = generate_encoded_digest(signature)
          %Q(#{@access_key}:#{encoded_digest}:#{signature})
        end

      end # module UploadToken
end # module Qiniu
