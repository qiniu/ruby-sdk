# -*- encoding: utf-8 -*-
require 'qiniu/basic/utils'

module Qiniu
  module Fop
    class ImageView
      attr_accessor :mode, :width, :height, :quality, :format
      def initialize(mode=0, width=0, height=0, quality=0, format='')
        @mode = mode
        @width = width
        @height = height
        @quality = quality
        @format = format
      end

      def make_request(url)
        url += '?imageView/' + @mode.to_s
        url += '/w/%d' % @width.to_s if @width > 0
        url += '/h/%d' % @height.to_s if @height > 0
        url += '/q/%d' % @quality.to_s if @quality > 0
        url += '/format/%s' % @format unless @format.empty?
        url
      end

      def call(url)
        Qiniu::Rpc.get make_request(url)
      end
    end

    class ImageInfo
      def make_request(url)
        url + '?imageInfo'
      end

      def call(url)
        Qiniu::Rpc.get make_request(url)
      end
    end

    class Exif
      def make_request(url)
        url + '?exif'
      end

      def call(url)
        Qiniu::Rpc.get make_request(url)
      end
    end
  end
end

