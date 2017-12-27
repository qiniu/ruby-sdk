# -*- encoding: utf-8 -*-

require 'json'
require 'qiniu/tokens/access_token'
require 'qiniu/utils'

### DownloadToken 类已经过时，请改用 Qiniu::Auth.authorize_download_url 方法 ###
### 或 Qiniu::Auth.authorize_download_url_2 方法                             ###

module Qiniu
  class DownloadToken < AccessToken

    include Utils

    attr_accessor :pattern, :expires_in

    def initialize(opts = {})
      @pattern = opts[:pattern]
      @expires_in = opts[:expires_in] || 3600
    end

    def generate_signature
      params = {"S" => @pattern, "E" => Time.now.to_i + @expires_in}
      Utils.urlsafe_base64_encode(params.to_json)
    end

    def generate_token
      signature = generate_signature
      encoded_digest = generate_encoded_digest(signature)
      "#{@access_key}:#{encoded_digest}:#{signature}"
    end

  end # moidule DownloadToken
end # module Qiniu
