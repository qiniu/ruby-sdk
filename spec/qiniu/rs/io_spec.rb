# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/auth'
require 'qiniu/rs/io'
require 'digest/sha1'

module Qiniu
  module RS
    describe IO do

      before :all do
        code, data = Qiniu::RS::Auth.exchange_by_password!("test@qbox.net", "test")
        code.should == 200
        data.should be_an_instance_of(Hash)
        data["access_token"].should_not be_empty
        data["refresh_token"].should_not be_empty
        data["refresh_token"].should_not be_empty
        puts data.inspect

        code2, data2 = Qiniu::RS::IO.put_auth()
        code2.should == 200
        data2["url"].should_not be_empty
        data2["expiresIn"].should_not be_zero
        puts data2.inspect

        @put_url = data2["url"]
        @bucket = "test"
        @key = Digest::SHA1.hexdigest (Time.now.to_i+rand(100)).to_s
      end

      context ".put_file" do
        it "should works" do
          code, data = Qiniu::RS::IO.put_file(@put_url, __FILE__, @bucket, @key)
          code.should == 200
          puts data.inspect
        end
      end

    end
  end
end
