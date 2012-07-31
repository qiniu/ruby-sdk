# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/eu'

module Qiniu
  module RS
    describe EU do

      before :all do
        @customer_id = "awhy.xu@gmail.com"
      end

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
