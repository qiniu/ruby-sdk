# -*- encoding: utf-8 -*-

require 'json'
require 'qiniu/tokens/access_token'
require 'qiniu/rs/utils'

module Qiniu
  module RS
      class DownloadToken < AccessToken

        include Utils

        attr_accessor :pattern, :expires_in

        def initialize(opts = {})
          @pattern = opts[:pattern] || "*"
          @expires_in = opts[:expires_in] || 3600
        end

        def generate_signature
          params = {"S" => @pattern, "E" => Time.now.to_i + @expires_in}
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
