# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/auth'
require 'qiniu/rs'
require 'qiniu/rs/image'

module Qiniu
  module RS
    describe Image do

      before :all do
=begin
        code, data = Qiniu::RS::Auth.exchange_by_password!("test@qbox.net", "test")
        code.should == 200
        data.should be_an_instance_of(Hash)
        data["access_token"].should_not be_empty
        data["refresh_token"].should_not be_empty
        data["refresh_token"].should_not be_empty
        puts data.inspect
=end

        @bucket = "test_images_12345"
        @key = "image_logo_for_test.png"

        local_file = File.expand_path('../' + @key, __FILE__)

        result = Qiniu::RS.drop(@bucket)
        result.should_not be_false
        puts result.inspect

        put_url = Qiniu::RS.put_auth(10)
        put_url.should_not be_false
        put_url.should_not be_empty
        result = Qiniu::RS.upload :url => put_url,
                                  :file => local_file,
                                  :bucket => @bucket,
                                  :key => @key,
                                  :mime_type => "image/png",
                                  :enable_crc32_check => true
        result.should be_true


        result = Qiniu::RS.get(@bucket, @key)
        result["url"].should_not be_empty
        puts result.inspect
        @source_image_url = result["url"]

        @mogrify_options = {
            :thumbnail => "!120x120r",
            :gravity => "center",
            :crop => "!120x120a0a0",
            :quality => 85,
            :rotate => 45,
            :format => "jpg",
            :auto_orient => true
        }
      end

      context ".info" do
        it "should works" do
          code, data = Qiniu::RS::Image.info(@source_image_url)
          code.should == 200
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
