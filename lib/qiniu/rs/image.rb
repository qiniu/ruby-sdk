# -*- encoding: utf-8 -*-

module Qiniu
  module RS
    module Image
      class << self
        include Utils

        def info(url)
          Utils.http_request url + '/imageInfo', nil, {:method => :get}
        end

        def preivew_url(url, spec)
          url + '/imagePreview/' + spec.to_s
        end

      end
    end
  end
end
