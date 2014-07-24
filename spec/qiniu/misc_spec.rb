# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/auth'
require 'qiniu'
require 'qiniu/misc'

module Qiniu
  module Misc
    describe Misc do

      before :all do
        @bucket = 'rubysdk'
      end

      after :all do
      end

      context ".set_protected" do
        it "should works" do
          code, data = Qiniu::Misc.set_protected(@bucket, 1)
          code.should == 200
          puts data.inspect
        end
      end

      context ".set_separator" do
        it "should works" do
          code, data = Qiniu::Misc.set_separator(@bucket, "-")
          code.should == 200
          puts data.inspect
        end
      end

      context ".set_style" do
        it "should works" do
          code, data = Qiniu::Misc.set_style(@bucket, "small.jpg", "imageMogr/auto-orient/thumbnail/!120x120r/gravity/center/crop/!120x120/quality/80")
          code.should == 200
          puts data.inspect
        end
      end

      context ".unset_style" do
        it "should works" do
          code, data = Qiniu::Misc.unset_style(@bucket, "small.jpg")
          code.should == 200
          puts data.inspect
        end
      end

    end
  end # module Misc
end # module Qiniu
