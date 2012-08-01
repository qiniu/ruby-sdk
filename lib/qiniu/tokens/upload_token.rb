# -*- encoding: utf-8 -*-

require 'json'
require 'qiniu/tokens/access_token'
require 'qiniu/rs/utils'

module Qiniu
  module RS
      class UploadToken < AccessToken

        include Utils

        attr_accessor :scope, :expires_in, :callback_url, :return_url

        def initialize(opts = {})
          @scope = opts[:scope]
          @expires_in = opts[:expires_in]
          @callback_url = opts[:callback_url]
          @return_url = opts[:return_url]
        end

        def generate_signature
          params = {:scope => @scope, :deadline => Time.now.to_i + @expires_in}
          params[:callbackUrl] = @callback_url if !@callback_url.nil? && !@callback_url.empty?
          params[:returnUrl] = @return_url if !@return_url.nil? && !@return_url.empty?
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
