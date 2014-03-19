# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/auth'
require 'qiniu'
require 'qiniu/fop'

module Qiniu
    module Fop
    describe Fop do

      before :all do

        ### 复用RubySDK-Test-Storage空间
        @bucket = 'RubySDK-Test-Storage'
        @bucket = make_unique_bucket(@bucket)

        ### 尝试创建空间
        result = Qiniu.mkbucket(@bucket)
        puts result.inspect

        pic_fname = "image_logo_for_test.png"
        @key = make_unique_key_in_bucket(pic_fname)

        local_file = File.expand_path('../' + pic_fname, __FILE__)

        upopts = {
            :scope => @bucket,
            :expires_in => 3600,
            :customer => "why404@gmail.com",
            :async_options => "imageView/1/w/120/h/120",
            :return_body => '{"size":$(fsize), "hash":$(etag), "width":$(imageInfo.width), "height":$(imageInfo.height)}'
        }
        uptoken = Qiniu.generate_upload_token(upopts)
        data = Qiniu.upload_file :uptoken => uptoken, :file => local_file, :bucket => @bucket, :key => @key
        puts data.inspect

        data["size"].should_not be_zero
        data["hash"].should_not be_empty
        data["width"].should_not be_zero
        data["height"].should_not be_zero

        result = Qiniu.get(@bucket, @key)
        result["url"].should_not be_empty
        puts result.inspect
        @source_image_url = result["url"]

        @mogrify_options = {
            :thumbnail => "!120x120>",
            :gravity => "center",
            :crop => "!120x120a0a0",
            :quality => 85,
            :rotate => 45,
            :format => "jpg",
            :auto_orient => true
        }
      end

      after :all do
        ### 不删除Bucket以备下次使用
      end

      context ".info" do
        it "should works" do
          code, data = Qiniu::Fop::Image.info(@source_image_url)
          code.should == 200
          puts data.inspect
        end
      end

=begin
      context ".exif" do
        it "should works" do
          code, data = Qiniu::Fop::Image.exif(@source_image_url)
          puts data.inspect
        end
      end
=end

      context ".mogrify_preview_url" do
        it "should works" do
          mogrify_preview_url = Qiniu::Fop::Image.mogrify_preview_url(@source_image_url, @mogrify_options)
          puts mogrify_preview_url.inspect
        end
      end

    end
    end # module Fop
end # module Qiniu
