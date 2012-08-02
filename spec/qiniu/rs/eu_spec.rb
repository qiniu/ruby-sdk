# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/io'
require 'qiniu/rs/pub'
require 'qiniu/rs/eu'

module Qiniu
  module RS
    describe EU do

      before :all do
        @customer_id = "awhy.xu@gmail.com"
        @bucket = "wm_test_bucket"
        @key = "image_logo_for_test.png"

        local_file = File.expand_path('../' + @key, __FILE__)
        upopts = {:scope => @bucket, :expires_in => 3600, :customer => @customer_id}
        uptoken = Qiniu::RS.generate_upload_token(upopts)

        code, data = Qiniu::RS::IO.upload_with_token(uptoken, local_file, @bucket, @key, nil, nil, nil, true)
        code.should == 200
        puts data.inspect

        code2, data2 = Qiniu::RS::Pub.set_separator(@bucket, "-")
        code2.should == 200
        puts data2.inspect

        code3, data3 = Qiniu::RS::Pub.set_style(@bucket, "small.jpg", "imageView/1/w/120/h/120/q/85/format/jpg/watermark/1")
        code3.should == 200
        puts data3.inspect
      end

      #after :all do
      #  result = Qiniu::RS.drop(@bucket)
      #  result.should_not be_false
      #end

      context ".set_watermark" do
        it "should works" do
          options = {
            :text => "Powered by QiniuRS"
          }
          code, data = Qiniu::RS::EU.set_watermark(@customer_id, options)
          code.should == 200
          puts data.inspect
        end
      end

      context ".get_watermark" do
        it "should works" do
          code, data = Qiniu::RS::EU.get_watermark(@customer_id)
          code.should == 200
          puts data.inspect
        end
      end

    end
  end
end
