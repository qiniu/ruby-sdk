# -*- encoding: utf-8 -*-
# vim: sw=2 ts=2

require 'spec_helper'
require 'qiniu/auth'
require 'qiniu'
require 'qiniu/fop'

module Qiniu
  module Fop
    module Persistance
      describe Persistance do

        before :all do
          @bucket = 'rubysdk'

          pic_fname = "image_logo_for_test.png"
          @key = make_unique_key_in_bucket(pic_fname)

          local_file = File.expand_path('../' + pic_fname, __FILE__)

          ### 检查测试文件存在性
          code, body, headers = Qiniu::Storage.stat(@bucket, @key)
          if code == 404 || code == 612 then
            # 文件不存在，尝试上传
            pp = Qiniu::Auth::PutPolicy.new(@bucket, @key)
            code, body, headers = Qiniu::Storage.upload_with_put_policy(
              pp,
              local_file,
              nil,
              nil,
              bucket: @bucket
            )
            puts "Put a test file for Persistance cases"
            puts code.inspect
            puts body.inspect
            puts headers.inspect
          end
        end

        context ".pfop" do
          it "should works" do
            pp = Persistance::PfopPolicy.new(
              @bucket,
              @key,
              'imageView2/1/w/80/h/80',   # fops
              'www.baidu.com'             # notify_url
            )

            code, data, headers = Qiniu::Fop::Persistance.pfop(pp)
            puts data.inspect
            expect(code).to eq(200)
          end
        end

        context ".prefop" do
          it "should works" do
            code, data, headers = Qiniu::Fop::Persistance.prefop('fakePersistentId')
            puts code.inspect
            puts data.inspect
            puts headers.inspect
            expect(code).to eq(404)
          end
        end

        context ".p1" do
          it "should works" do
            url = 'http://fake.qiniudn.com/fake.jpg'
            fop = 'imageView2/1/w/80/h/80'
            target_url = "#{url}?p/1/#{CGI.escape(fop).gsub('+', '%20')}"

            p1_url = Qiniu::Fop::Persistance.generate_p1_url(url, fop)
            puts p1_url.inspect
            expect(p1_url).to eq(target_url)
          end
        end
      end
    end # module Persistance
  end # module Fop
end # module Qiniu
