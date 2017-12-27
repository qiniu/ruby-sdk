# -*- encoding: utf-8 -*-

require 'qiniu/http'

module Qiniu
  module Misc
    class << self
      def set_protected(bucket, protected_mode)
        url = Config.settings[:pub_host] + %Q(/accessMode/#{bucket}/mode/#{protected_mode})
        return HTTP.management_post(url)
      end # set_protected

      def set_separator(bucket, separator)
        encoded_separator = Utils.urlsafe_base64_encode(separator)
        url = Config.settings[:pub_host] + %Q(/separator/#{bucket}/sep/#{encoded_separator})
        return HTTP.management_post(url)
      end # set_separator

      def set_style(bucket, name, style)
        encoded_name = Utils.urlsafe_base64_encode(name)
        encoded_style = Utils.urlsafe_base64_encode(style)
        url = Config.settings[:pub_host] + %Q(/style/#{bucket}/name/#{encoded_name}/style/#{encoded_style})
        return HTTP.management_post(url)
      end # set_style

      def unset_style(bucket, name)
        encoded_name = Utils.urlsafe_base64_encode(name)
        url = Config.settings[:pub_host] + %Q(/unstyle/#{bucket}/name/#{encoded_name})
        return HTTP.management_post(url)
      end # unset_style
    end # class << self

  end # module Misc
end # module Qiniu

