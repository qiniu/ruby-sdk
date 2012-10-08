# -*- encoding: utf-8 -*-

require 'uri'
require 'cgi'
require 'json'
require 'zlib'
require 'base64'
require 'rest_client'
require 'hmac-sha1'
require 'qiniu/rs/exceptions'

module Qiniu
  module RS
    module Utils extend self

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

      def is_response_ok?(status_code)
          status_code/100 == 2
      end

      def response_error(status_code, errmsg)
          [status_code, {"error" => errmsg}]
      end

      def debug(msg)
          if Config.settings[:enable_debug]
              Log.logger.debug(msg)
          end
      end

      def send_request_with url, data = nil, options = {}
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
        unless is_response_ok?(code)
          raise RequestFailed.new("Request Failed", response)
        else
          data = {}
          body = response.respond_to?(:body) ? response.body : {}
          data = safe_json_parse(body) unless body.empty?
        end
        [code, data]
      end

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
            data = safe_json_parse(body) unless body.empty?
          end
          [code, data]
        end
      end

      def upload_multipart_data(url, filepath, action_string, callback_query_string = '', uptoken = nil)
          post_data = {
            :params => callback_query_string,
            :action => action_string,
            :file => File.new(filepath, 'rb'),
            :multipart => true
          }
          post_data[:auth] = uptoken unless uptoken.nil?
          http_request url, post_data
      end

      def generate_query_string(params)
        return params if params.is_a?(String)
        total_param = params.map { |key, value| %Q(#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s).gsub('+', '%20')}) }
        total_param.join("&")
      end

      def crc32checksum(filepath)
        File.open(filepath, "rb") { |f| Zlib.crc32 f.read }
      end

      def generate_qbox_signature(url, params)
        access_key = Config.settings[:access_key]
        secret_key = Config.settings[:secret_key]
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
