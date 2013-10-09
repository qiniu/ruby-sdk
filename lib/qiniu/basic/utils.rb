# -*- encoding: utf-8 -*-

require 'uri'
require 'cgi'
require 'json'
require 'zlib'
require 'base64'
require 'rest_client'
require 'hmac-sha1'
require 'qiniu/basic/exceptions'

module Qiniu
  module Utils

    class << self

      def urlsafe_base64_encode content
        Base64.encode64(content).strip.gsub('+', '-').gsub('/','_').gsub(/\r?\n/, '')
      end

      def urlsafe_base64_decode encoded_content
        Base64.decode64 encoded_content.gsub('_','/').gsub('-', '+')
      end

      def encode_entry_uri(bucket, key)
        entry_uri = bucket + ':' + key
        urlsafe_base64_encode(entry_uri)
      end

      def safe_json_parse(data)
        JSON.parse(data)
      rescue JSON::ParserError
        {}
      end

      def generate_query_string(params)
        return params if params.is_a?(String)
        total_param = params.map { |key, value| %Q(#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}) }
        total_param.join("&")
      end

      def crc32checksum(filepath)
        File.open(filepath, "rb") { |f| Zlib.crc32 f.read }
      end

      def generate_qbox_signature(url, params)
        access_key = Qiniu::Conf.settings[:access_key]
        secret_key = Qiniu::Conf.settings[:secret_key]
        uri = URI.parse(url)
        signature = uri.path
        query_string = uri.query
        signature += '?' + query_string if !query_string.nil? && !query_string.empty?
        signature += "\n"
        if params.is_a?(Hash)
          params_string = generate_query_string(params)
          signature += params_string
        end
        hmac = HMAC::SHA1.new(secret_key)
        hmac.update(signature)
        encoded_digest = urlsafe_base64_encode(hmac.digest)
        %Q(#{access_key}:#{encoded_digest})
      end

    end
  end
end
