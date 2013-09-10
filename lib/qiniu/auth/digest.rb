# -*- encoding: utf-8 -*-

require 'uri'
require 'qiniu/basic/utils'


module Qiniu
  module Auth
    module Digest

      # class Mac: hold access key & secret key and generate tokens
      class Mac

		attr_accessor :access_key

        def initialize(accesskey = nil, secretkey = nil)
          @access_key = accesskey || Qiniu::Conf.settings[:access_key] 
          @secret_key = secretkey || Qiniu::Conf.settings[:secret_key]
        end

        def sign_it(data)
          hmac = HMAC::SHA1.new(@secret_key)
          hmac.update(data)
          return Qiniu::Utils.urlsafe_base64_encode(hmac.digest)
        end

        private :sign_it

        def sign(data)
          return %Q(#{@access_key}:#{sign_it(data)})
        end

        def sign_with_data(data)
          data64 = Qiniu::Utils.urlsafe_base64_encode(data)
          return %Q(#{sign(data64)}:#{data64})
        end

        def generate_access_token(path, query, body)
          access = path
          access += '?' + query if !query.nil? && !query.empty?
          access += "\n";
          access += body if !body.nil? && !body.empty?
          return %Q(#{@access_key}:#{sign_it(access)})
        end

      end


    end
  end
end
