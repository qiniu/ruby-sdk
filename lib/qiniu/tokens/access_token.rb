# -*- encoding: utf-8 -*-

require 'hmac-sha1'
require 'qiniu/rs/config'
require 'qiniu/rs/utils'

module Qiniu
  module RS
      class AccessToken

        include Utils

        attr_accessor :access_key, :secret_key

        def generate_encoded_digest(signature)
          hmac = HMAC::SHA1.new(@secret_key)
          hmac.update(signature)
          urlsafe_base64_encode(hmac.digest)
        end

      end
  end
end
