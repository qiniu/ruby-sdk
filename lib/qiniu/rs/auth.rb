# -*- encoding: utf-8 -*-

require 'qiniu/rs/exceptions'

module Qiniu
  module RS
    module Auth

      class << self

        include Utils

        def call_with_signature(url, data, retry_times = 0, options = {})
          http_request url, data, options.merge({:qbox_signature_token => generate_qbox_signature(url, data)})
        end

        def request(url, data = nil, options = {})
          Auth.call_with_signature(url, data, 0, options)
        end

      end

    end # module Auth
  end # module RS
end # module Qiniu
