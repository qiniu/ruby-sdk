# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/auth'
require 'qiniu/rs'
require 'qiniu/rs/image'

module Qiniu
  module RS
    describe Image do

      before :each do
=begin
        code, data = Qiniu::RS::Auth.exchange_by_password!("test@qbox.net", "test")
        code.should == 200
        data.should be_an_instance_of(Hash)
        data["access_token"].should_not be_empty
        data["refresh_token"].should_not be_empty
        data["refresh_token"].should_not be_empty
        puts data.inspect
=end

        @bucket = "test_images"
        @key = "image_logo_for_test.png"

        local_file = File.expand_path('../' + @key, __FILE__)

        put_url = Qiniu::RS.put_auth(10)
        put_url.should_not be_false
        put_url.should_not be_empty
        result = Qiniu::RS.upload :url => put_url,
                                  :file => local_file,
                                  :bucket => @bucket,
                                  :key => @key,
                                  :enable_crc32_check => true
        result.should be_true
      end

      context ".info" do
        it "should works" do
          result = Qiniu::RS.get(@bucket, @key)
          result["url"].should_not be_empty
          puts result.inspect
          code, data = Qiniu::RS::Image.info(result["url"])
          code.should == 200
          puts data.inspect
        end
      end

    end
  end
end
