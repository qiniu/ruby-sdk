# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/auth'
require 'qiniu'
require 'qiniu/fop'

module Qiniu
  module Fop
    describe Fop do

      before :all do
        @bucket = 'rubysdk'
        pic_fname = "image_logo_for_test.png"
        @key = make_unique_key_in_bucket(pic_fname)

        local_file = File.expand_path('../' + pic_fname, __FILE__)

        upopts = {
            :scope => @bucket,
            :expires_in => 3600,
            :customer => "why404@gmail.com",
            :async_options => "imageView/1/w/120/h/120",
            :return_body => '{"size":$(fsize), "hash":$(etag), "width":$(imageInfo.width), "height":$(imageInfo.height)}'
        }
        uptoken = Qiniu.generate_upload_token(upopts)
        data = Qiniu.upload_file :uptoken => uptoken, :file => local_file, :bucket => @bucket, :key => @key
        puts data.inspect

        expect(data["size"]).not_to be_zero
        expect(data["hash"]).not_to be_empty
        expect(data["width"]).not_to be_zero
        expect(data["height"]).not_to be_zero

        code, domains, = Qiniu::Storage.domains(@bucket)
        expect(code).to eq(200)
        expect(domains).not_to be_empty
        @bucket_domain = domains.first['domain']
        @source_image_url = "http://#{@bucket_domain}/#{@key}"

        @mogrify_options = {
            :thumbnail => "!120x120>",
            :gravity => "center",
            :crop => "!120x120a0a0",
            :quality => 85,
            :rotate => 45,
            :format => "jpg",
            :auto_orient => true
        }
      end

      # context ".info" do
      #   it "should works" do
      #     pending('This function cannot work for private bucket file')
      #     code, data = Qiniu::Fop::Image.info(@source_image_url)
      #     puts data.inspect
      #     expect(code).to eq(200)
      #   end
      # end

      # context ".exif" do
      #   it "should works" do
      #     pending('This function cannot work for private bucket file')
      #     code, data, headers = Qiniu::Fop::Image.exif("http://#{@bucket_domain}/gogopher.jpg")
      #     puts data.inspect
      #     puts headers.inspect
      #     expect(code).to eq(200)
      #   end
      # end

      # context ".mogrify_preview_url" do
      #   it "should works" do
      #     pending('This function cannot work for private bucket file')
      #     mogrify_preview_url = Qiniu::Fop::Image.mogrify_preview_url(@source_image_url, @mogrify_options)
      #     puts mogrify_preview_url.inspect
      #   end
      # end
    end
  end # module Fop
end # module Qiniu
