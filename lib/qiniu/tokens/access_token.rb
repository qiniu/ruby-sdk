# -*- encoding: utf-8 -*-

require 'hmac-sha1'
require 'qiniu/config'
require 'qiniu/utils'

### AccessToken 类已经过时，请改用 Qiniu::Auth.generate_acctoken 方法 ###

module Qiniu
      class AccessToken

        include Utils

        attr_accessor :access_key, :secret_key

        def generate_encoded_digest(signature)
          hmac = HMAC::SHA1.new(@secret_key)
          hmac.update(signature)
          urlsafe_base64_encode(hmac.digest)
        end

      end # AccessToken
end # module Qiniu
