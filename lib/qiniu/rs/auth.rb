# -*- encoding: utf-8 -*-

require 'qiniu/rs/exceptions'

module Qiniu
  module RS
    module Auth
      class << self
        include Utils

        def call_with_signature(url, data, retry_times = 0, options = {})
          code, data = http_request url, data, options.merge({:qbox_signature_token => generate_qbox_signature(url, data, options[:mime])})
          [code, data]
        end

        def request(url, data = nil, options = {})
              code, data = Auth.call_with_signature(url, data, 0, options)
          [code, data]
        end

      end
    end
  end
end
