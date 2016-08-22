# -*- encoding: utf-8 -*-
# vim: sw=2 ts=2

require 'digest/sha1'
require 'spec_helper'
require 'qiniu/auth'
require 'qiniu/management'
require 'qiniu'

module Qiniu
  module Storage
    shared_examples "Management Specs" do
      before :all do
        @key = Digest::SHA1.hexdigest((Time.now.to_i+rand(100)).to_s)
        @key = make_unique_key_in_bucket(@key)

        @key2 = @key + rand(100).to_s

        pp = Auth::PutPolicy.new(@bucket, @key)
        code, data, raw_headers = Qiniu::Storage.upload_with_put_policy(
          pp,
          __FILE__,
          nil,
          nil,
          bucket: @bucket
        )
        code.should == 200
      end

      ### 列举Bucket
      context ".buckets" do
        it "should works" do
          code, data = Storage.buckets
          code.should == 200
          puts data.inspect
        end
      end

      context ".stat" do
        it "should works" do
          code, data = Storage.stat(@bucket, @key)
          puts data.inspect
          code.should == 200
        end
      end

      context ".get" do
        it "should works" do
          code, data = Storage.get(@bucket, @key)
          puts data.inspect
          code.should == 200
        end
      end

      context ".batch" do
        it "should works" do
          code, data = Storage.batch("stat", @bucket, [@key])
          puts data.inspect
          code.should == 200
        end
      end

      context ".batch_stat" do
        it "should works" do
          code, data = Storage.batch_stat(@bucket, [@key])
          puts data.inspect
          code.should == 200
        end
      end

      context ".batch_get" do
        it "should works" do
          code, data = Storage.batch_get(@bucket, [@key])
          puts data.inspect
          code.should == 200
        end
      end

      context ".batch_copy" do
        it "should works" do
          code, data = Storage.batch_copy @bucket, @key, @bucket, @key2
          puts data.inspect
          code.should == 200

          code, data = Storage.delete @bucket, @key2
          puts data.inspect
          code.should == 200
        end
      end

      context ".batch_move" do
        it "should works" do
          code, data = Storage.batch_move [@bucket, @key, @bucket, @key2]
          puts data.inspect
          code.should == 200

          code3, data3 = Storage.batch_move [@bucket, @key2, @bucket, @key]
          puts data3.inspect
          code3.should == 200
        end
      end

      context ".move" do
        it "should works" do
          code, data = Storage.move(@bucket, @key, @bucket, @key2)
          puts data.inspect
          code.should == 200

          code2, data2 = Storage.stat(@bucket, @key2)
          puts data2.inspect
          code2.should == 200

          code3, data3 = Storage.move(@bucket, @key2, @bucket, @key)
          puts data3.inspect
          code3.should == 200
        end
      end

      context ".copy" do
        it "should works" do
          code, data = Storage.copy(@bucket, @key, @bucket, @key2)
          puts data.inspect
          code.should == 200

          code, data = Storage.delete(@bucket, @key2)
          puts data.inspect
          code.should == 200
        end
      end

      context ".delete" do
        it "should works" do
          code, data = Storage.delete(@bucket, @key)
          puts data.inspect
          code.should == 200
        end
      end

      context ".fetch" do
        it "should works" do
          code, data = Qiniu::Storage.fetch(@bucket, "https://www.baidu.com/robots.txt", @key)
          code.should == 200
          puts data.inspect
        end
      end
      
      context "batch chgm" do 
        it "should works" do 
          code, data = Storage.stat(@bucket, @key)
          code.should == 200
          old_mineType = data['mimeType']
          new_mineType = old_mineType + "v2"
          code, data =  Storage.batch_chgm(@bucket, [@key],new_mineType)
          code, data =  Storage.stat(@bucket, @key)
          code.should == 200
          data['mimeType'].should == new_mineType
        end
      end
      context ".chgm" do 
        it "should works" do 
          code, data = Storage.stat(@bucket, @key)
          code.should == 200
          old_mineType = data['mimeType']
          new_mineType = old_mineType + "v2"
          code, data =  Storage.chgm(@bucket, @key,new_mineType)
          code, data =  Storage.stat(@bucket, @key)
          code.should == 200
          data['mimeType'].should == new_mineType
        end
      end

    end

    describe 'When multi_region is disabled' do
      before :all do
        Config.settings[:multi_region] = false
        @bucket = 'rubysdk'
      end
      include_examples 'Management Specs'
    end

    describe 'When multi_region is enabled' do
      describe 'for z0 bucket' do
        before :all do
          Config.settings[:multi_region] = true
          @bucket = 'rubysdk'
        end
        include_examples 'Management Specs'
      end

      describe 'for z1 bucket' do
        before :all do
          Config.settings[:multi_region] = true
          @bucket = 'rubysdk-bc'
        end
        include_examples 'Management Specs'
      end
    end
  end # module Storage
end # module Qiniu
