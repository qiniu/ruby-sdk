# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/auth'
require 'qiniu/storage'
require 'digest/sha1'

module Qiniu
  module Storage
    describe Storage do

      before :all do
        @bucket = 'RubySdkTest' + (Time.now.to_i+rand(1000)).to_s
        @key = Digest::SHA1.hexdigest((Time.now.to_i+rand(100)).to_s)

        @localfile1 = "bigfile.txt"
        File.open(@localfile1, "w"){|f| 5242888.times{ f.write(rand(9).to_s) }}
        @key1 = Digest::SHA1.hexdigest(@localfile1+Time.now.to_s)

        @localfile2 = "bigfile2.txt"
        File.open(@localfile2, "w"){|f| (1 << 22).times{ f.write(rand(9).to_s) }}
        @key2 = Digest::SHA1.hexdigest(@localfile2+Time.now.to_s)

        @localfile3 = "bigfile3.txt"
        File.open(@localfile3, "w"){|f| (1 << 23).times{ f.write(rand(9).to_s) }}
        @key3 = Digest::SHA1.hexdigest(@localfile3+Time.now.to_s)

        @localfile4 = "smallfile.txt"
        File.open(@localfile4, "w"){|f| (1 << 20).times{ f.write(rand(9).to_s) }}
        @key4 = Digest::SHA1.hexdigest(@localfile4+Time.now.to_s)

        result = Qiniu.mkbucket(@bucket)
        puts result.inspect
        result.should be_true
      end

      after :all do
        File.unlink(@localfile1) if File.exists?(@localfile1)
        File.unlink(@localfile2) if File.exists?(@localfile2)
        File.unlink(@localfile3) if File.exists?(@localfile3)
        File.unlink(@localfile4) if File.exists?(@localfile4)

        result = Qiniu.drop(@bucket)
        puts result.inspect
        result.should_not be_false
      end

      context ".put_file" do
        it "should works" do
          code, data = Qiniu::Storage.put_file(__FILE__, @bucket, @key, 'application/x-ruby', 'customMeta', true)
          code.should == 200
          puts data.inspect
        end
      end

      context ".upload_with_token" do
        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data = Qiniu::Storage.upload_with_token(uptoken, __FILE__, @bucket, @key, nil, nil, nil, true)
          code.should == 200
          puts data.inspect
        end
      end

      context ".upload_with_token_2" do
        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :endUser => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)

          code, data = Qiniu::Storage.upload_with_token_2(uptoken, __FILE__, @key)

          code.should == 200
          puts data.inspect
        end
      end # .upload_with_token_2

      context ".resumable_upload_with_token" do
        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data = Qiniu::Storage.resumable_upload_with_token(uptoken, @localfile1, @bucket, @key1)
          puts data.inspect
          (code/100).should == 2
        end
      end

      context ".stat" do
        it "should exists" do
          code, data = Qiniu::RS.stat(@bucket, @key1)
          puts data.inspect
          code.should == 200
        end
      end

      context ".delete" do
        it "should works" do
          code, data = Qiniu::RS.delete(@bucket, @key1)
          puts data.inspect
          code.should == 200
        end
      end

      context ".resumable_upload_with_token2" do
        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data = Qiniu::Storage.resumable_upload_with_token(uptoken, @localfile2, @bucket, @key2)
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

      context ".resumable_upload_with_token3" do
        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data = Qiniu::Storage.resumable_upload_with_token(uptoken, @localfile3, @bucket, @key3)
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

      context ".resumable_upload_with_token4" do
        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data = Qiniu::Storage.resumable_upload_with_token(uptoken, @localfile4, @bucket, @key4)
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
  end # module Storage
end # module Qiniu
