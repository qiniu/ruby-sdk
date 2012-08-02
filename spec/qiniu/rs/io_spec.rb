# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/auth'
require 'qiniu/rs/io'
require 'digest/sha1'

module Qiniu
  module RS
    describe IO do

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
        @bucket = "test"
        @key = Digest::SHA1.hexdigest (Time.now.to_i+rand(100)).to_s
      end

      context ".upload_file" do
        it "should works" do
          code, data = Qiniu::RS::IO.put_auth()
          code.should == 200
          data["url"].should_not be_empty
          data["expiresIn"].should_not be_zero
          puts data.inspect
          code2, data2 = Qiniu::RS::IO.upload_file(data["url"], __FILE__, @bucket, @key)
          code2.should == 200
          puts data2.inspect
        end
      end

      context ".put_file" do
        it "should works" do
          code, data = Qiniu::RS::IO.put_file(__FILE__, @bucket, @key, 'application/x-ruby', 'customMeta', true)
          code.should == 200
          puts data.inspect
        end
      end

      context ".upload_with_token" do
        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => 1}
          uptoken = Qiniu::RS.generate_upload_token(upopts)
          code, data = Qiniu::RS::IO.upload_with_token(uptoken, __FILE__, @bucket, @key, nil, nil, nil, true)
          code.should == 200
          puts data.inspect
        end
      end

    end
  end
end
