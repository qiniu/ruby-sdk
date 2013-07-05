# -*- encoding: utf-8 -*-

require 'cgi'
require 'json'
require 'qiniu/tokens/access_token'

module Qiniu
  module RS
 
=begin

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
=end


      class Mac

        include Utils

        attr_accessor :access_key, :secret_key

        def initiailze(accesskey, secretkey)
          @access_key = accesskey
          @secret_key = secretkey
        end

        def generate_encoded_digest(signature)
          hmac = HMAC::SHA1.new(@secret_key)
          hmac.update(signature)
          urlsafe_base64_encode(hmac.digest)
        end

        def generate_access_token(url, params)
          
          if @access_key.nil? || @access_key.empty?
            || @secret_key.nil? || @secret_key.empty? then
            raise "Invalid Access Key or Secret Key"
          end

          uri = URI.parse(url)
          access = uri.path
          query_string = uri.query
          access += '?' + query_string if !query_string.nil? && !query_string.empty?
          access += "\n";
          if params.is_a?(Hash)
            total_param = params.map do |key, value|
              %Q(#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s).gsub('+', '%20')})
            end
            access += total_param.join("&")
          end
          hmac = HMAC::SHA1.new(@secret_key)
          hmac.update(access)
          encoded_digest = urlsafe_base64_encode(hmac.digest)
          %Q(#{@access_key}:#{encoded_digest})
        end

      end

      class << self
        def make_base_url(domain, key)
          return "http://" + domain + "/" + URI.escape(key)
        end
      end

  end
end
