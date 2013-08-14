# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/rs'
require 'qiniu/basic/exceptions'
require 'digest/sha1'
require 'qiniu/auth/digest'
require 'qiniu/io'
require 'qiniu/rs/tokens'
require 'qiniu/basic/utils'
require 'qiniu/fop'

module Qiniu
  describe Fop do
    before :all do
      @image_url = 'http://qiniuphotos.qiniudn.com/gogopher.jpg'
    end

    context '.Exif' do
      it 'get exif info' do
# @gist exif
        exif = Qiniu::Fop::Exif.new
        code, ret = exif.call @image_url
        puts code, ret
# @endgist
        code == 200 && ret.length > 5
      end
    end

    context '.ImageInfo' do
      it 'get ImageInfo' do
# @gist imageinfo
        ii = Qiniu::Fop::ImageInfo.new
        code, ret = ii.call @image_url
        puts code, ret
# @endgist
        code == 200 && ret['format'] && ret['width']
      end
    end

    context '.ImageView' do
# @gist imageview1
      iv = Qiniu::Fop::ImageView.new
# @endgist

      it 'test url 1' do
# @gist imageview2
        iv.height = 100
        iv.width = 40
        returl = iv.make_request @image_url
        puts returl
# @endgist
        returl == 'http://qiniuphotos.qiniudn.com/gogopher.jpg?imageView/0/w/40/h/100'
      end

      it 'test url 2' do
        iv.quality = 20
        iv.format = 'jpg'
        returl = iv.make_request @image_url
        returl == 'http://qiniuphotos.qiniudn.com/gogopher.jpg?imageView/0/w/40/h/100/q/20/format/jpg'
      end
    end

  end
end
