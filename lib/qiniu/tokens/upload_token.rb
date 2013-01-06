# -*- encoding: utf-8 -*-

require 'json'
require 'qiniu/tokens/access_token'
require 'qiniu/rs/utils'

module Qiniu
  module RS
      class UploadToken < AccessToken

        include Utils

        attr_accessor :scope, :expires_in, :callback_url, :callback_body_type, :customer, :escape

        def initialize(opts = {})
          @scope = opts[:scope]
          @expires_in = opts[:expires_in] || 3600
          @callback_url = opts[:callback_url]
          @callback_body_type = opts[:callback_body_type]
          @customer = opts[:customer]
          @escape = opts[:escape]
        end

        def generate_signature
          params = {:scope => @scope, :deadline => Time.now.to_i + @expires_in}
          params[:callbackUrl] = @callback_url if !@callback_url.nil? && !@callback_url.empty?
          params[:callbackBodyType] = @callback_body_type if !@callback_body_type.nil? && !@callback_body_type.empty?
          params[:customer] = @customer if !@customer.nil? && !@customer.empty?
          params[:escape] = 1 if @escape == 1 || @escape == true
          Utils.urlsafe_base64_encode(params.to_json)
        end

        def generate_token
          signature = generate_signature
          encoded_digest = generate_encoded_digest(signature)
          %Q(#{@access_key}:#{encoded_digest}:#{signature})
        end

      end
  end
end
