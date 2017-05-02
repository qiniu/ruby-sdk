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
          hmac_digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), @secret_key, signature)
          urlsafe_base64_encode([hmac_digest].pack('H*'))
        end

      end # AccessToken
end # module Qiniu
