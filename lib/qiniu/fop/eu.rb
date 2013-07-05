# -*- encoding: utf-8 -*-

module Qiniu
  module RS
    module EU
      class << self
        include Utils

        def set_watermark(customer_id, options = {})
          Auth.request Config.settings[:eu_host] + '/wmset', options.merge({:customer => customer_id})
        end

        def get_watermark(customer_id = nil)
          post_data = customer_id.nil? ? nil : {:customer => customer_id}
          Auth.request Config.settings[:eu_host] + '/wmget', post_data
        end

      end
    end
  end
end

