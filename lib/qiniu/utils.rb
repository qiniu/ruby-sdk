# -*- encoding: utf-8 -*-

require 'uri'
require 'cgi'
require 'json'
require 'zlib'
require 'base64'
require 'rest_client'
require 'qiniu/exceptions'

module Qiniu
    module Utils extend self

      def urlsafe_base64_encode content
        Base64.encode64(content).strip.tr('+', '-').tr('/','_').gsub(/\r?\n/, '')
      end

      def urlsafe_base64_decode encoded_content
        Base64.decode64 encoded_content.tr('_','/').tr('-', '+')
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

      def debug(msg)
          if Config.settings[:enable_debug]
              Log.logger.debug(msg)
          end
      end

      ### 已过时，仅作为兼容接口保留
      def send_request_with(url, data = nil, options = {})
        options[:method] = Config.settings[:method] unless options[:method]
        options[:content_type] = Config.settings[:content_type] unless options[:content_type]
        header_options = {
          :accept => :json,
          :user_agent => Config.settings[:user_agent]
        }
        auth_token = nil
        if !options[:qbox_signature_token].nil? && !options[:qbox_signature_token].empty?
          auth_token = 'QBox ' + options[:qbox_signature_token]
        elsif !options[:upload_signature_token].nil? && !options[:upload_signature_token].empty?
          auth_token = 'UpToken ' + options[:upload_signature_token]
        elsif options[:access_token]
          auth_token = 'Bearer ' + options[:access_token]
        end
        header_options.merge!('Authorization' => auth_token) unless auth_token.nil?
        case options[:method]
        when :get
          response = RestClient.get(url, header_options)
        when :post
          header_options.merge!(:content_type => options[:content_type])
          response = RestClient.post(url, data, header_options)
        end
        code = response.respond_to?(:code) ? response.code.to_i : 0
        raise RequestFailed.new("Request Failed", response) unless HTTP.is_response_ok?(code)
        data = {}
        body = response.respond_to?(:body) ? response.body : {}
        raw_headers = response.respond_to?(:raw_headers) ? response.raw_headers : {}
        data = safe_json_parse(body) unless body.empty?
        [code, data, raw_headers]
      end # send_request_with

      ### 已过时，仅作为兼容接口保留
      def http_request url, data = nil, options = {}
        retry_times = 0
        begin
          retry_times += 1
          send_request_with url, data, options
        rescue Errno::ECONNRESET => err
          if Config.settings[:auto_reconnect] && retry_times < Config.settings[:max_retry_times]
            retry
          else
            Log.logger.error err
          end
        rescue => e
          Log.logger.warn "#{e.message} => Utils.http_request('#{url}')"
          code = 0
          data = {}
          body = {}
          if e.respond_to? :response
            res = e.response
            code = res.code.to_i if res.respond_to? :code
            body = res.respond_to?(:body) ? res.body : ""
            raw_headers = res.respond_to?(:raw_headers) ? res.raw_headers : {}
            data = safe_json_parse(body) unless body.empty?
          end
          [code, data, raw_headers]
        end
      end

      def crc32checksum(filepath)
        File.open(filepath, "rb") { |f| Zlib.crc32 f.read }
      end

    end # module Utils
end # module Qiniu
