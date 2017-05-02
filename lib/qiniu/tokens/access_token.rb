# -*- encoding: utf-8 -*-

require 'openssl'
require 'qiniu/config'
require 'qiniu/utils'

### AccessToken 类已经过时，请改用 Qiniu::Auth.generate_acctoken 方法 ###

module Qiniu
      class AccessToken

        include Utils

        attr_accessor :access_key, :secret_key

        def generate_encoded_digest(signature)
          raw_hmac_digest = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), @secret_key, signature)
          urlsafe_base64_encode(raw_hmac_digest)
        end

      end # AccessToken
end # module Qiniu
