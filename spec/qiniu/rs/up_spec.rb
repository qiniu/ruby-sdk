# -*- encoding: utf-8 -*-

require 'digest/sha1'
require 'spec_helper'
require 'qiniu/rs/rs'
require 'qiniu/rs/up'

module Qiniu
  module RS
    describe UP do

      before :all do
        @localfile = "bigfile.txt"
        File.open(@localfile, "w"){|f| 5242888.times{f.write(rand(9).to_s)}}
        @bucket = 'RubySdkTest' + (Time.now.to_i+rand(1000)).to_s
        @key = Digest::SHA1.hexdigest(@localfile+Time.now.to_s)

        code, data = Qiniu::RS::RS.mkbucket(@bucket)
        puts [code, data].inspect
        code.should == 200
      end

      after :all do
        File.unlink(@localfile) if File.exists?(@localfile)

        code, data = Qiniu::RS::RS.drop(@bucket)
        puts [code, data].inspect
        code.should == 200
      end

      context ".upload_with_token" do
        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu::RS.generate_upload_token(upopts)
          code, data = Qiniu::RS::UP.upload_with_token(uptoken, @localfile, @bucket, @key)
          puts data.inspect
          (code/100).should == 2
        end
      end

      context ".stat" do
        it "should exists" do
          code, data = Qiniu::RS::RS.stat(@bucket, @key)
          puts data.inspect
          code.should == 200
        end
      end

      context ".delete" do
        it "should works" do
          code, data = Qiniu::RS::RS.delete(@bucket, @key)
          puts data.inspect
          code.should == 200
        end
      end

    end
  end
end
