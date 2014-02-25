# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/auth'
require 'qiniu/io'
require 'digest/sha1'

module Qiniu
  module IO
    describe IO do

      before :all do
        @bucket = 'RubySdkTest' + (Time.now.to_i+rand(1000)).to_s
        @key = Digest::SHA1.hexdigest((Time.now.to_i+rand(100)).to_s)

        result = Qiniu.mkbucket(@bucket)
        puts result.inspect
        result.should be_true
      end

      after :all do
        result = Qiniu.drop(@bucket)
        puts result.inspect
        result.should_not be_false
      end

      context ".put_file" do
        it "should works" do
          code, data = Qiniu::IO.put_file(__FILE__, @bucket, @key, 'application/x-ruby', 'customMeta', true)
          code.should == 200
          puts data.inspect
        end
      end

      context ".upload_with_token" do
        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data = Qiniu::IO.upload_with_token(uptoken, __FILE__, @bucket, @key, nil, nil, nil, true)
          code.should == 200
          puts data.inspect
        end
      end

      context ".upload_with_token_2" do
        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :endUser => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)

          code, data = Qiniu::IO.upload_with_token_2(uptoken, __FILE__, @key)

          code.should == 200
          puts data.inspect
        end
      end # .upload_with_token_2

    end
  end # module IO
end # module Qiniu
