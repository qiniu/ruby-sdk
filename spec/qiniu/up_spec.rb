# -*- encoding: utf-8 -*-

require 'digest/sha1'
require 'spec_helper'
require 'qiniu'
require 'qiniu/up'

module Qiniu
  module UP
    describe UP do

      before :all do
        @localfile = "bigfile.txt"
        File.open(@localfile, "w"){|f| 5242888.times{ f.write(rand(9).to_s) }}
        @bucket = 'RubySdkTest' + (Time.now.to_i+rand(1000)).to_s
        @key = Digest::SHA1.hexdigest(@localfile+Time.now.to_s)

        @localfile2 = "bigfile2.txt"
        File.open(@localfile2, "w"){|f| (1 << 22).times{ f.write(rand(9).to_s) }}
        @key2 = Digest::SHA1.hexdigest(@localfile2+Time.now.to_s)

        @localfile3 = "bigfile3.txt"
        File.open(@localfile3, "w"){|f| (1 << 23).times{ f.write(rand(9).to_s) }}
        @key3 = Digest::SHA1.hexdigest(@localfile3+Time.now.to_s)

        @localfile4 = "smallfile.txt"
        File.open(@localfile4, "w"){|f| (1 << 20).times{ f.write(rand(9).to_s) }}
        @key4 = Digest::SHA1.hexdigest(@localfile4+Time.now.to_s)

        code, data = Qiniu::RS.mkbucket(@bucket)
        puts [code, data].inspect
        code.should == 200
      end

      after :all do
        File.unlink(@localfile) if File.exists?(@localfile)
        File.unlink(@localfile2) if File.exists?(@localfile2)
        File.unlink(@localfile3) if File.exists?(@localfile3)
        File.unlink(@localfile4) if File.exists?(@localfile4)

        code, data = Qiniu::RS.drop(@bucket)
        puts [code, data].inspect
        code.should == 200
      end

      context ".upload_with_token" do
        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data = Qiniu::UP.upload_with_token(uptoken, @localfile, @bucket, @key)
          puts data.inspect
          (code/100).should == 2
        end
      end

      context ".stat" do
        it "should exists" do
          code, data = Qiniu::RS.stat(@bucket, @key)
          puts data.inspect
          code.should == 200
        end
      end

      context ".delete" do
        it "should works" do
          code, data = Qiniu::RS.delete(@bucket, @key)
          puts data.inspect
          code.should == 200
        end
      end

      context ".upload_with_token2" do
        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data = Qiniu::UP.upload_with_token(uptoken, @localfile2, @bucket, @key2)
          puts data.inspect
          (code/100).should == 2
        end
      end

      context ".stat" do
        it "should exists" do
          code, data = Qiniu::RS.stat(@bucket, @key2)
          puts data.inspect
          code.should == 200
        end
      end

      context ".delete" do
        it "should works" do
          code, data = Qiniu::RS.delete(@bucket, @key2)
          puts data.inspect
          code.should == 200
        end
      end

      context ".upload_with_token3" do
        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data = Qiniu::UP.upload_with_token(uptoken, @localfile3, @bucket, @key3)
          puts data.inspect
          (code/100).should == 2
        end
      end

      context ".stat" do
        it "should exists" do
          code, data = Qiniu::RS.stat(@bucket, @key3)
          puts data.inspect
          code.should == 200
        end
      end

      context ".delete" do
        it "should works" do
          code, data = Qiniu::RS.delete(@bucket, @key3)
          puts data.inspect
          code.should == 200
        end
      end

      context ".upload_with_token4" do
        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data = Qiniu::UP.upload_with_token(uptoken, @localfile4, @bucket, @key4)
          puts data.inspect
          (code/100).should == 2
        end
      end

      context ".stat" do
        it "should exists" do
          code, data = Qiniu::RS.stat(@bucket, @key4)
          puts data.inspect
          code.should == 200
        end
      end

      context ".delete" do
        it "should works" do
          code, data = Qiniu::RS.delete(@bucket, @key4)
          puts data.inspect
          code.should == 200
        end
      end

    end
  end # module UP
end # module Qiniu
