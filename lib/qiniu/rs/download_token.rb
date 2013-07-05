# -*- encoding: utf-8 -*-

require 'json'
require 'qiniu/auth/digest'
require 'qiniu/basic/utils'
require 'uri'

module Qiniu
  module Rs

      class GetPolicy

        include Utils

        attr_accessor :Expires

        def initialize
          @Expires = 3600
        end

        def make_request(base_url, mac = nil)
          
          if base_url == nil || base_url.empty() then
            raise 'Invalid argument: "base_url" '
          end

          if mac.nil? then
            mac = Mac.New(Config.settings[:access_key], Config.settings[:secret_key])
          end

          deadline = Time.now.to_i + @Expires

          if base_url['?'] != nil then
            base_url += '&'
          else
            base_url += '?'
          end

          base_url += "e=" + deadline.to_s

          token = mac.generate_encoded_digest(base_url)

          return base_url + "&token=" + token
        end

      end

	  class << self

        # MakeBaseUrl(): construct url with domain & key
        def MakeBaseUrl(domain, key)
          return "http://" + domain + "/" + URI.escape(key)
        end

	  end

  end
end
