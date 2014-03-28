# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/auth'
require 'qiniu/storage'
require 'digest/sha1'

module Qiniu
  module Auth 
    describe Auth do

      before :all do
        @bucket = 'RubySDK-Test-Private'
        @bucket = make_unique_bucket(@bucket)

        ### 尝试创建Bucket
        result = Qiniu::Storage.make_a_private_bucket(@bucket)
        puts result.inspect
      end

      after :all do
        ### 不删除Bucket以备下次使用
      end

      ### 测试私有资源下载
      context ".download_private_file" do
        it "should works" do
          ### 生成Key
          key = 'a_private_file'
          key = make_unique_key_in_bucket(key)
          puts "key=#{key}"

          ### 上传测试文件
          pp = Auth::PutPolicy.new(@bucket, key)
          code, data, raw_headers = Qiniu::Storage.upload_with_put_policy(
            pp,
            __FILE__
          )
          code.should == 200
          puts data.inspect
          puts raw_headers.inspect

          ### 获取下载地址
          code, data = Qiniu::Storage.get(@bucket, key)
          code.should == 200
          puts data.inspect

          url = data['url']

          ### 授权下载地址（不带参数）
          download_url = Qiniu::Auth.authorize_download_url(url)
          puts "download_url=#{download_url}"

          result = RestClient.get(download_url)
          result.code.should == 200
          result.body.should_not be_empty

          ### 授权下载地址（带参数）
          download_url = Qiniu::Auth.authorize_download_url(url + '?download/a.m3u8')
          puts "download_url=#{download_url}"

          result = RestClient.get(download_url)
          result.code.should == 200
          result.body.should_not be_empty

          ### 删除文件
          code, data = Qiniu::Storage.delete(@bucket, key)
          code.should == 200
          puts data.inspect
        end
      end

    end
  end # module Storage
end # module Qiniu
