# -*- encoding: utf-8 -*-

module Qiniu
  module RS
    module Image
      class << self
        include Utils

        def info(url)
          Utils.http_request url + '/imageInfo', nil, {:method => :get}
        end

        def exif(url)
          Utils.http_request url + '?exif', nil, {:method => :get}
        end

        def preivew_url(url, spec)
          url + '/imagePreview/' + spec.to_s
        end

        def mogrify_preview_url(source_image_url, options)
          source_image_url + '?' + generate_mogrify_params_string(options)
        end

        def generate_mogrify_params_string(options = {})
          opts = {}
          options.each do |k, v|
            opts[k.to_s] = v
          end
          params_string = ""
          keys = ["thumbnail", "gravity", "crop", "quality", "rotate", "format"]
          keys.each do |key|
            params_string += %Q(/#{key}/#{opts[key]}) unless opts[key].nil?
          end
          params_string += '/auto-orient' unless opts["auto_orient"].nil?
          'imageMogr' + URI.escape(params_string)
        end

      end
    end
  end
end
