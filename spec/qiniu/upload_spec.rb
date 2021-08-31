# -*- encoding: utf-8 -*-
# vim: sw=2 ts=2

require 'spec_helper'
require 'qiniu/auth'
require 'qiniu/storage'
require 'digest/sha1'

module Qiniu
  module Storage
    shared_examples "Upload Specs" do
      before :all do
        Config.settings[:multi_region] = true

        @key = Digest::SHA1.hexdigest((Time.now.to_i+rand(100)).to_s)
        @key = make_unique_key_in_bucket(@key)
        puts "key=#{@key}"

        @localfile_5m = "5M.txt"
        File.open(@localfile_5m, "w"){|f| 5242888.times{ f.write(rand(9).to_s) }}
        @key_5m = Digest::SHA1.hexdigest(@localfile_5m+Time.now.to_s)
        @key_5m = make_unique_key_in_bucket(@key_5m)
        puts "key_5m=#{@key_5m}"

        @localfile_4m = "4M.txt"
        File.open(@localfile_4m, "w"){|f| (1 << 22).times{ f.write(rand(9).to_s) }}
        @key_4m = Digest::SHA1.hexdigest(@localfile_4m+Time.now.to_s)
        @key_4m = make_unique_key_in_bucket(@key_4m)
        puts "key_4m=#{@key_4m}"

        @localfile_8m = "8M.txt"
        File.open(@localfile_8m, "w"){|f| (1 << 23).times{ f.write(rand(9).to_s) }}
        @key_8m = Digest::SHA1.hexdigest(@localfile_8m+Time.now.to_s)
        @key_8m = make_unique_key_in_bucket(@key_8m)
        puts "key_8m=#{@key_8m}"

        @localfile_1m = "1M.txt"
        File.open(@localfile_1m, "w"){|f| (1 << 20).times{ f.write(rand(9).to_s) }}
        @key_1m = Digest::SHA1.hexdigest(@localfile_1m+Time.now.to_s)
        @key_1m = make_unique_key_in_bucket(@key_1m)
        puts "key_1m=#{@key_1m}"
      end

      after :all do
        ### 清除本地临时文件
        File.unlink(@localfile_5m) if File.exists?(@localfile_5m)
        File.unlink(@localfile_4m) if File.exists?(@localfile_4m)
        File.unlink(@localfile_8m) if File.exists?(@localfile_8m)
        File.unlink(@localfile_1m) if File.exists?(@localfile_1m)
      end

      ### 测试单文件直传
      context ".upload_with_token" do
        before do
          Qiniu::Storage.delete(@bucket, @key)
        end

        after do
          code, data = Qiniu::Storage.delete(@bucket, @key)
          puts data.inspect
          code.should == 200
        end

        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data, raw_headers = Qiniu::Storage.upload_with_token(
            uptoken,
            __FILE__,
            @bucket,
            @key,
            nil,
            nil,
            nil,
            true
          )
          code.should == 200
          puts data.inspect
          puts raw_headers.inspect

          code, data = Qiniu::Storage.stat(@bucket, @key)
          puts data.inspect
          code.should == 200
        end
      end

      context ".upload_with_token_2" do
        before do
          Qiniu::Storage.delete(@bucket, @key)
        end

        after do
          code, data = Qiniu::Storage.delete(@bucket, @key)
          puts data.inspect
          code.should == 200
        end

        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :endUser => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)

          code, data, raw_headers = Qiniu::Storage.upload_with_token_2(
            uptoken,
            __FILE__,
            @key,
            nil,
            bucket: @bucket
          )

          code.should == 200
          puts data.inspect
          puts raw_headers.inspect

          code, data = Qiniu::Storage.stat(@bucket, @key)
          puts data.inspect
          code.should == 200
        end
      end # .upload_with_token_2

      context ".upload_with_put_policy" do
        before do
          Qiniu::Storage.delete(@bucket, @key)
        end

        after do
          code, data = Qiniu::Storage.delete(@bucket, @key)
          puts data.inspect
          code.should == 200
        end

        it "should works" do
          pp = Qiniu::Auth::PutPolicy.new(@bucket, @key)
          pp.end_user = "why404@gmail.com"
          puts 'put_policy=' + pp.to_json

          code, data, raw_headers = Qiniu::Storage.upload_with_put_policy(
            pp,
            __FILE__,
            @key + '-not-equal',
            nil,
            bucket: @bucket
          )
          code.should_not == 200
          puts data.inspect
          puts raw_headers.inspect

          code, data, raw_headers = Qiniu::Storage.upload_with_put_policy(
            pp,
            __FILE__,
            @key,
            nil,
            bucket: @bucket
          )

          code.should == 200
          puts data.inspect
          puts raw_headers.inspect

          code, data = Qiniu::Storage.stat(@bucket, @key)
          puts data.inspect
          code.should == 200
        end
      end # .upload_with_put_policy

      context ".upload_buffer_with_put_policy" do
        before do
          Qiniu::Storage.delete(@bucket, @key)
        end

        after do
          code, data = Qiniu::Storage.delete(@bucket, @key)
          puts data.inspect
          code.should == 200
        end

        it "should works" do
          pp = Qiniu::Auth::PutPolicy.new(@bucket, @key)
          pp.end_user = "amethyst.black@gmail.com"
          puts 'put_policy=' + pp.to_json

          test_line = 'This is a test line for testing put_buffer function.'
          code, data, raw_headers = Qiniu::Storage.upload_buffer_with_put_policy(
            pp,
            test_line,
            @key,
            nil,
            bucket: @bucket
          )
          code.should == 200
          puts data.inspect
          puts raw_headers.inspect

          code, data = Qiniu::Storage.stat(@bucket, @key)
          puts data.inspect
          code.should == 200
        end
      end # .upload_buffer_with_put_policy

      ## 测试断点续上传
      context ".resumable_upload_with_token" do
        before do
          Qiniu::Storage.delete(@bucket, @key_5m)
        end

        after do
          code, data = Qiniu::Storage.delete(@bucket, @key_5m)
          puts data.inspect
          code.should == 200
        end

        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data, raw_headers = Qiniu::Storage.resumable_upload_with_token(
            uptoken,
            @localfile_5m,
            @bucket,
            @key_5m
          )
          (code/100).should == 2
          puts data.inspect
          puts raw_headers.inspect
          puts "key_5m=#{@key_5m}"

          code, data = Qiniu::Storage.stat(@bucket, @key_5m)
          puts data.inspect
          code.should == 200
        end
      end

      context ".resumable_upload_with_token2" do
        before do
          Qiniu::Storage.delete(@bucket, @key_4m)
        end

        after do
          code, data = Qiniu::Storage.delete(@bucket, @key_4m)
          puts data.inspect
          code.should == 200
        end

        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data, raw_headers = Qiniu::Storage.resumable_upload_with_token(
            uptoken,
            @localfile_4m,
            @bucket,
            @key_4m
          )
          (code/100).should == 2
          puts data.inspect
          puts raw_headers.inspect
          puts "key_4m=#{@key_4m}"

          code, data = Qiniu::Storage.stat(@bucket, @key_4m)
          puts data.inspect
          code.should == 200
        end
      end

      context ".resumable_upload_with_token3" do
        before do
          Qiniu::Storage.delete(@bucket, @key_8m)
        end

        after do
          code, data = Qiniu::Storage.delete(@bucket, @key_8m)
          puts data.inspect
          code.should == 200
        end

        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data, raw_headers = Qiniu::Storage.resumable_upload_with_token(
            uptoken,
            @localfile_8m,
            @bucket,
            @key_8m
          )
          (code/100).should == 2
          puts data.inspect
          puts raw_headers.inspect
          puts "key_8m=#{@key_8m}"

          code, data = Qiniu::Storage.stat(@bucket, @key_8m)
          puts data.inspect
          code.should == 200
        end
      end

      context ".resumable_upload_with_token4" do
        before do
          Qiniu::Storage.delete(@bucket, @key_1m)
        end

        after do
          code, data = Qiniu::Storage.delete(@bucket, @key_1m)
          puts data.inspect
          code.should == 200
        end

        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data, raw_headers = Qiniu::Storage.resumable_upload_with_token(
            uptoken,
            @localfile_1m,
            @bucket,
            @key_1m
          )
          (code/100).should == 2
          puts data.inspect
          puts raw_headers.inspect
          puts "key_1m=#{@key_1m}"

          code, data = Qiniu::Storage.stat(@bucket, @key_1m)
          puts data.inspect
          code.should == 200
        end
      end

      context ".resumable_upload_with_token_v2" do
        before do
          Qiniu::Storage.delete(@bucket, @key_1m)
        end

        after do
          code, data = Qiniu::Storage.delete(@bucket, @key_1m)
          puts data.inspect
          code.should == 200
        end

        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          puts "uptoken is #{uptoken}"
          code, data, raw_headers = Qiniu::Storage.resumable_upload_with_token(
            uptoken,
            @localfile_1m,
            @bucket,
            @key_1m,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            'v2',
            4 * 1024 * 1024
          )
          (code/100).should == 2
          puts data.inspect
          puts raw_headers.inspect
          puts "key_1m=#{@key_1m}"

          code, data = Qiniu::Storage.stat(@bucket, @key_1m)
          puts data.inspect
          code.should == 200
        end
      end

      context ".resumable_upload_with_token2_v2" do
        before do
          Qiniu::Storage.delete(@bucket, @key_4m)
        end

        after do
          code, data = Qiniu::Storage.delete(@bucket, @key_4m)
          puts data.inspect
          code.should == 200
        end

        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data, raw_headers = Qiniu::Storage.resumable_upload_with_token(
            uptoken,
            @localfile_4m,
            @bucket,
            @key_5m,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            'v2',
            4 * 1024 * 1024
          )
          (code/100).should == 2
          puts data.inspect
          puts raw_headers.inspect
          puts "key_4m=#{@key_4m}"

          code, data = Qiniu::Storage.stat(@bucket, @key_4m)
          puts data.inspect
          code.should == 200
        end
      end

      context ".resumable_upload_with_token3_v2" do
        before do
          Qiniu::Storage.delete(@bucket, @key_8m)
        end

        after do
          code, data = Qiniu::Storage.delete(@bucket, @key_8m)
          puts data.inspect
          code.should == 200
        end

        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data, raw_headers = Qiniu::Storage.resumable_upload_with_token(
            uptoken,
            @localfile_8m,
            @bucket,
            @key_8m,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            'v2',
            4 * 1024 * 1024
          )
          (code/100).should == 2
          puts data.inspect
          puts raw_headers.inspect
          puts "key_8m=#{@key_8m}"

          code, data = Qiniu::Storage.stat(@bucket, @key_8m)
          puts data.inspect
          code.should == 200
        end
      end

      context ".resumable_upload_with_token4_v2" do
        before do
          Qiniu::Storage.delete(@bucket, @key_5m)
        end

        after do
          code, data = Qiniu::Storage.delete(@bucket, @key_5m)
          puts data.inspect
          code.should == 200
        end

        it "should works" do
          upopts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
          uptoken = Qiniu.generate_upload_token(upopts)
          code, data, raw_headers = Qiniu::Storage.resumable_upload_with_token(
            uptoken,
            @localfile_5m,
            @bucket,
            @key_5m,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            'v2'
          )
          (code/100).should == 2
          puts data.inspect
          puts raw_headers.inspect
          puts "key_5m=#{@key_5m}"

          code, data = Qiniu::Storage.stat(@bucket, @key_5m)
          puts data.inspect
          code.should == 200
        end
      end
    end

    describe 'for na0 bucket' do
      before :all do
        @bucket = 'rubysdk-na0'
      end
      include_examples 'Upload Specs'
    end

    describe 'for as0 bucket' do
      before :all do
        @bucket = 'rubysdk-as0'
      end
      include_examples 'Upload Specs'

      it 'should raise BucketIsMissing error' do
        upopts = {:scope => @bucket, :expires_in => 3600, :endUser => "why404@gmail.com"}
        uptoken = Qiniu.generate_upload_token(upopts)
        expect do
          Qiniu::Storage.upload_with_token_2(
            uptoken,
            __FILE__,
            @key,
            )
        end.to raise_error('upload_with_token_2 requires :bucket option when multi_region is enabled')
      end
    end
  end # module Storage
end # module Qiniu