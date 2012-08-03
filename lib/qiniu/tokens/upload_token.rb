# -*- encoding: utf-8 -*-

require 'json'
require 'qiniu/tokens/access_token'
require 'qiniu/rs/utils'

module Qiniu
  module RS
      class UploadToken < AccessToken

        include Utils

        attr_accessor :scope, :expires_in, :callback_url, :callback_body, :customer

        def initialize(opts = {})
          @scope = opts[:scope]
          @expires_in = opts[:expires_in]
          @callback_url = opts[:callback_url]
          @callback_body = opts[:callback_body]
          @customer = opts[:customer]
        end

        def generate_signature
          params = {:scope => @scope, :deadline => Time.now.to_i + @expires_in}
          params[:callbackUrl] = @callback_url if !@callback_url.nil? && !@callback_url.empty?
          params[:callbackBodyType] = @callback_body if !@callback_body.nil? && !@callback_body.empty?
          params[:customer] = @customer if !@customer.nil? && !@customer.empty?
          urlsafe_base64_encode(params.to_json)
        end

        def generate_token
          signature = generate_signature
          encoded_digest = generate_encoded_digest(signature)
          %Q(#{@access_key}:#{encoded_digest}:#{signature})
        end

      end
  end
end
