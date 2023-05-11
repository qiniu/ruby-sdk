# -*- encoding: utf-8 -*-
# vim: sw=2 ts=2

require 'spec_helper'
require 'qiniu/auth'
require 'qiniu/config'
require 'qiniu/storage'
require 'digest/sha1'

module Qiniu
  module Auth
    describe Auth do

      before :all do
        @bucket = 'rubysdk'
      end
      after :all do
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
            __FILE__,
            nil,
            nil,
            bucket: @bucket
          )
          expect(code).to eq(200)
          puts data.inspect
          puts raw_headers.inspect

          ### 获取下载地址
          code, domains, = Qiniu::Storage.domains(@bucket)

          expect(code).to eq(200)
          expect(domains).not_to be_empty
          domain = domains.first['domain']
          url = "http://#{domain}/#{key}"

          ### 授权下载地址（不带参数）
          download_url = Qiniu::Auth.authorize_download_url(url)
          puts "download_url=#{download_url}"

          result = RestClient.get(download_url)
          expect(result.code).to eq(200)
          expect(result.body).not_to be_empty

          ### 授权下载地址（带参数）
          download_url = Qiniu::Auth.authorize_download_url(url, fop: 'qhash/md5')
          puts "download_url=#{download_url}"

          result = RestClient.get(download_url)
          expect(result.code).to eq(200)
          expect(result.body).not_to be_empty

          ### 删除文件
          code, data = Qiniu::Storage.delete(@bucket, key)
          puts data.inspect
          expect(code).to eq(200)
        end

        it "should generate uphosts and global for multi_region" do
          origin_multi_region = Config.settings[:multi_region]
          begin
            Config.settings[:multi_region] = true
            ### 生成Key
            key = 'a_private_file'
            key = make_unique_key_in_bucket(key)
            puts "key=#{key}"

            ### 生成 PutPolicy
            pp = Auth::PutPolicy.new(@bucket, key)
            expect(pp.instance_variable_get(:@uphosts)).to eq ["upload.qiniup.com", "up.qiniup.com"]
            expect(pp.instance_variable_get(:@global)).to be false
          ensure
            Config.settings[:multi_region] = origin_multi_region
          end
        end
      end
    end

    ### 测试回调签名
    context ".authenticate_callback_request" do
      it "should works" do
        url = 'https://www.qiniu.com:8080/test.php'
        body = 'name=xxx&size=1234'
        expect(Qiniu::Auth.authenticate_callback_request('ABCD', url, body)).to be_falsey
        expect(Qiniu::Auth.authenticate_callback_request(Config.settings[:access_key], url, body)).to be_falsey
        expect(Qiniu::Auth.authenticate_callback_request('QBox ' + Config.settings[:access_key] + ':', url, body)).to be_falsey
        expect(Qiniu::Auth.authenticate_callback_request('QBox ' + Config.settings[:access_key] + ':????', url, body)).to be_falsey

        acctoken = Qiniu::Auth.generate_qbox_token(url, body)
        auth_str = 'QBox ' + acctoken

        expect(Qiniu::Auth.authenticate_callback_request(auth_str + '  ', url, body)).to be_falsey
        expect(Qiniu::Auth.authenticate_callback_request(auth_str, url, body)).to be_truthy
        expect(Qiniu::Auth.authenticate_callback_request(acctoken, url, body)).to be_truthy
        expect(Qiniu::Auth.authenticate_callback_request(acctoken, url, body, 'application/json')).to be_falsey
      end
    end

    ### 测试回调签名 v2
    context ".authenticate_callback_request_v2" do
      it "should works" do
        url = 'https://www.qiniu.com:8080/test.php'
        body = 'name=xxx&size=1234'
        expect(Qiniu::Auth.authenticate_callback_request_v2('ABCD', :post, url, {}, body)).to be_falsey
        expect(Qiniu::Auth.authenticate_callback_request_v2(Config.settings[:access_key], :post, url, {}, body)).to be_falsey
        expect(Qiniu::Auth.authenticate_callback_request_v2('QBox ' + Config.settings[:access_key] + ':', :post, url, {}, body)).to be_falsey
        expect(Qiniu::Auth.authenticate_callback_request_v2('QBox ' + Config.settings[:access_key] + ':????', :post, url, {}, body)).to be_falsey
        expect(Qiniu::Auth.authenticate_callback_request_v2('Qiniu ' + Config.settings[:access_key] + ':', :post, url, {}, body)).to be_falsey
        expect(Qiniu::Auth.authenticate_callback_request_v2('Qiniu ' + Config.settings[:access_key] + ':????', :post, url, {}, body)).to be_falsey

        acctoken = Qiniu::Auth.generate_qbox_token(url, body)
        auth_str = 'QBox ' + acctoken

        expect(Qiniu::Auth.authenticate_callback_request_v2(auth_str + '  ', :post, url, {}, body)).to be_falsey
        expect(Qiniu::Auth.authenticate_callback_request_v2(auth_str, :post, url, {}, body)).to be_truthy
        expect(Qiniu::Auth.authenticate_callback_request_v2(acctoken, :post, url, {}, body)).to be_truthy
        expect(Qiniu::Auth.authenticate_callback_request_v2(auth_str, :post, url, {'Content-Type' => 'application/x-www-form-urlencoded'}, body)).to be_truthy
        expect(Qiniu::Auth.authenticate_callback_request_v2(auth_str, :post, url, {'Content-Type' => 'application/json'}, body)).to be_falsey

        headers = {}
        acctoken = Qiniu::Auth.generate_qiniu_token(:post, url, headers, body)
        auth_str = 'Qiniu ' + acctoken

        expect(Qiniu::Auth.authenticate_callback_request_v2(auth_str + '  ', :post, url, headers, body)).to be_falsey
        expect(Qiniu::Auth.authenticate_callback_request_v2(auth_str, :post, url, headers, body)).to be_truthy
        expect(Qiniu::Auth.authenticate_callback_request_v2(acctoken, :post, url, headers, body)).to be_falsey
      end
    end
  end # module Auth

  module Exception_Auth
    describe Exception_Auth, :not_set_ak_sk => true do
      ### 测试未设置 ak/sk 的异常抛出情况
      context ".not_set_ak_sk" do
        it "should works" do
          puts Qiniu::Config.instance_variable_get("@settings").inspect

          begin
            uptoken = Qiniu::Auth.generate_uptoken({})
          rescue => e
            expect(e.message).to eq("Please set Qiniu's access_key and secret_key before authorize any tokens.")
          else
            fail "Not raise any exception."
          end

          begin
            download_url = Qiniu::Auth.authorize_download_url("http://test.qiniudn.com/a_private_file")
          rescue => e
            expect(e.message).to eq("Please set Qiniu's access_key and secret_key before authorize any tokens.")
          else
            fail "Not raise any exception."
          end

          begin
            acctoken = Qiniu::Auth.generate_qbox_token("http://rsf.qbox.me/list")
          rescue => e
            expect(e.message).to eq("Please set Qiniu's access_key and secret_key before authorize any tokens.")
          else
            fail "Not raise any exception."
          end
        end
      end
    end
  end # module Exception_Auth
end # module Qiniu
