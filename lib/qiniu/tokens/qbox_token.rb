# -*- encoding: utf-8 -*-

require 'cgi'
require 'json'
require 'qiniu/tokens/access_token'

module Qiniu
  module RS
      class QboxToken < AccessToken

        include Utils

        attr_accessor :url, :params

        def initialize(opts = {})
          @url = opts[:url]
          @params = opts[:params]
        end

        def generate_signature
          uri = URI.parse(@url)
          signature = uri.path
          query_string = uri.query
          signature += '?' + query_string if !query_string.nil? && !query_string.empty?
          signature += "\n"
          if @params.is_a?(Hash)
              params_string = Utils.generate_query_string(@params)
              signature += params_string
          end
          signature
        end

        def generate_token
          encoded_digest = generate_encoded_digest(generate_signature)
          %Q(#{@access_key}:#{encoded_digest})
        end

      end
  end
end
