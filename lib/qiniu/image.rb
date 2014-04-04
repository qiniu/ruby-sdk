# -*- encoding: utf-8 -*-

module Qiniu
  module Fop
    module Image
      class << self
        include Utils

        def info(url)
          return HTTP.api_get(url + '?imageInfo')
        end # info

        def exif(url)
          return HTTP.api_get(url + '?exif')
        end # exif

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
    end # module Image
  end # module Fop
end # module Qiniu
