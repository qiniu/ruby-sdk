# -*- encoding: utf-8 -*-

require 'json'
require 'qiniu/auth'
require 'qiniu/rs/utils'
require 'uri'

module Qiniu
  module RS
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

          if mac == nil then
            mac = Mac.New()
            mac.access_key = Config.settings[:access_key]
            mac.secret_key = Config.settings[:secret_key]
            if mac.access_key == nil || mac.access_key.empty() ||
              mac.secret_key == nil || mac.secret_key.empty() then
              raise "Invalid Access Key or Secret Key"
            end
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

  end
end
