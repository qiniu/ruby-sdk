# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/auth'
require 'qiniu/rs'
require 'qiniu/rs/image'

module Qiniu
  module RS
    describe Image do

      before :all do

        @bucket = 'RubySdkTest' + (Time.now.to_i+rand(1000)).to_s
        @key = "image_logo_for_test.png"

        result = Qiniu::RS.mkbucket(@bucket)
        puts result.inspect
        result.should be_true

        local_file = File.expand_path('../' + @key, __FILE__)

        upopts = {
            :scope => @bucket,
            :expires_in => 3600,
            :customer => "why404@gmail.com",
            :async_options => "imageView/1/w/120/h/120",
            :return_body => '{"size":$(fsize), "hash":$(etag), "width":$(imageInfo.width), "height":$(imageInfo.height)}'
        }
        uptoken = Qiniu::RS.generate_upload_token(upopts)
        data = Qiniu::RS.upload_file :uptoken => uptoken, :file => local_file, :bucket => @bucket, :key => @key
        puts data.inspect

        data["size"].should_not be_zero
        data["hash"].should_not be_empty
        data["width"].should_not be_zero
        data["height"].should_not be_zero

        result = Qiniu::RS.get(@bucket, @key)
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
        result = Qiniu::RS.drop(@bucket)
        puts result.inspect
        result.should_not be_false
      end

      context ".info" do
        it "should works" do
          code, data = Qiniu::RS::Image.info(@source_image_url)
          code.should == 200
          puts data.inspect
        end
      end

      context ".exif" do
        it "should works" do
          code, data = Qiniu::RS::Image.exif(@source_image_url)
          puts data.inspect
        end
      end

      context ".mogrify_preview_url" do
        it "should works" do
          mogrify_preview_url = Qiniu::RS::Image.mogrify_preview_url(@source_image_url, @mogrify_options)
          puts mogrify_preview_url.inspect
        end
      end

    end
  end
end
