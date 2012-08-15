# -*- encoding: utf-8 -*-

module Qiniu
  module RS
    module Pub
      class << self
        include Utils

        def set_protected(bucket, protected_mode)
          host = Config.settings[:pub_host]
          Auth.request %Q(#{host}/accessMode/#{bucket}/mode/#{protected_mode})
        end

        def set_separator(bucket, separator)
          host = Config.settings[:pub_host]
          encoded_separator = Utils.urlsafe_base64_encode(separator)
          Auth.request %Q(#{host}/separator/#{bucket}/sep/#{encoded_separator})
        end

        def set_style(bucket, name, style)
          host = Config.settings[:pub_host]
          encoded_name = Utils.urlsafe_base64_encode(name)
          encoded_style = Utils.urlsafe_base64_encode(style)
          Auth.request %Q(#{host}/style/#{bucket}/name/#{encoded_name}/style/#{encoded_style})
        end

        def unset_style(bucket, name)
          host = Config.settings[:pub_host]
          encoded_name = Utils.urlsafe_base64_encode(name)
          Auth.request %Q(#{host}/unstyle/#{bucket}/name/#{encoded_name})
        end

      end
    end
  end
end

