# -*- encoding: utf-8 -*-

require 'qiniu/exceptions'

module Qiniu
    module Auth

      class << self

        include Utils

        def call_with_signature(url, data, retry_times = 0, options = {})
          code, data, raw_headers = http_request url, data, options.merge({:qbox_signature_token => generate_qbox_signature(url, data, options[:mime])})
          [code, data, raw_headers]
        end # call_with_signature

        def request(url, data = nil, options = {})
          code, data, raw_headers = Auth.call_with_signature(url, data, 0, options)
          [code, data, raw_headers]
        end # request

      end # class << self

    end # module Auth
end # module Qiniu
