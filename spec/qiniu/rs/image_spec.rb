# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/auth'
require 'qiniu/rs/rs'
require 'qiniu/rs/image'

module Qiniu
  module RS
    describe Image do

      before :all do
        code, data = Qiniu::RS::Auth.exchange_by_password!("test@qbox.net", "test")
        code.should == 200
        data.should be_an_instance_of(Hash)
        data["access_token"].should_not be_empty
        data["refresh_token"].should_not be_empty
        data["refresh_token"].should_not be_empty
        puts data.inspect

        @bucket = "test_images"
        @key = "test_image.jpg"
        code2, data2 = Qiniu::RS::RS.get(@bucket, @key)
        code2.should == 200
        data2["url"].should_not be_empty
        puts data2.inspect

        @download_url = data2["url"]
      end

      context ".info" do
        it "should works" do
          code, data = Qiniu::RS::Image.info(@download_url)
          code.should == 200
          puts data.inspect
        end
      end

    end
  end
end
