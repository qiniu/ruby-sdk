require 'net/http'
require 'uri'
require 'json'

module Qiniu

  module Refresh
    
    class << self
      def post urls=[], dirs=[]
        Net::HTTP.post URI('http://fusion.qiniuapi.com/v2/tune/refresh'), {"urls" => urls, "dirs" => dirs}.to_json, "Authorization" => "#{Config.settings[:access_key]}:#{access_token}", "Content-Type" => "application/json"
      end
    
      private
      def access_token
        `echo "/v2/tune/refresh" |openssl dgst -binary -hmac "#{Config.settings[:secret_key]}" -sha1 |base64 | tr + - | tr / _`
      end
    end
  end

end