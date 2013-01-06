# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/auth'
require 'qiniu/rs/io'
require 'digest/sha1'

module Qiniu
  module RS
    describe IO do

      before :all do
        @bucket = 'RubySdkTest' + (Time.now.to_i+rand(1000)).to_s
        @key = Digest::SHA1.hexdigest((Time.now.to_i+rand(100)).to_s)

        result = Qiniu::RS.mkbucket(@bucket)
        puts result.inspect
        result.should be_true
      end

      after :all do
        result = Qiniu::RS.drop(@bucket)
        puts result.inspect
        result.should_not be_false
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
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu::RS.generate_upload_token(upopts)
          code, data = Qiniu::RS::IO.upload_with_token(uptoken, __FILE__, @bucket, @key, nil, nil, nil, true)
          code.should == 200
          puts data.inspect
        end
      end

    end
  end
end
