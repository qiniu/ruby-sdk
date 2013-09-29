# -*- encoding: utf-8 -*-

require 'json'
require 'qiniu/auth/digest'
require 'qiniu/basic/utils'
require 'uri'

module Qiniu
  module Rs

	  class << self

        # MakeBaseUrl(): construct url with domain & key
        def make_base_url(domain, key)
          return "http://" + domain + "/" + URI.escape(key)
        end

	  end

      class GetPolicy

        include Utils

        attr_accessor :Expires

        def initialize
          @Expires = 3600
        end

        def make_request(base_url, mac = nil)
          
          if base_url.nil? || base_url.empty? then
            raise 'Invalid argument: "base_url" '
          end

          if mac.nil? then
            mac = Qiniu::Auth::Digest::Mac.new(Qiniu::Conf.settings[:access_key], Qiniu::Conf.settings[:secret_key])
          end

          deadline = Time.now.to_i + @Expires

          if base_url['?'] != nil then
            base_url += '&'
          else
            base_url += '?'
          end

          base_url += "e=" + deadline.to_s

          token = mac.sign(base_url)

          return base_url + "&token=" + token
        end

      end

# @gist put-policy
      class PutPolicy

        include Utils

        attr_accessor :scope, :callback_url, :callback_body, :return_url, :return_body, :async_ops, :end_user, :expires, :save_key

        def initialize(opts = {})
          @scope = opts[:scope]
          @callback_url = opts[:callback_url]
          @callback_body = opts[:callback_body]
          @return_url = opts[:return_url]
          @return_body = opts[:return_body]
          @async_ops = opts[:async_ops]
          @end_user = opts[:end_user]
          @expires = opts[:expires] || 3600
          @save_key = opts[:save_key]
        end
# @endgist

        def token(mac = nil)
          if mac.nil? then
            mac = Qiniu::Auth::Digest::Mac.new()
          end

          policy_json = marshal_policy()
          return mac.sign_with_data(policy_json)
        end

        def marshal_policy
          params = {:scope => @scope, :deadline => Time.now.to_i + @expires}
          params[:callbackUrl] = @callback_url unless @callback_url.nil?
          params[:callbackBody] = @callback_body unless @callback_body.nil?
          params[:returnUrl] = @return_url unless @return_url.nil?
          params[:returnBody] = @return_body unless @return_body.nil? 
          params[:asyncOps] = @async_ops unless @async_ops.nil?
          params[:endUser] = @end_user unless @end_user.nil?
          params[:saveKey] = @save_key unless @save_key.nil?
          return params.to_json
        end

      end
  end
end
