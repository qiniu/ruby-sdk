# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/auth'
require 'qiniu/rs/rs'
require 'qiniu/rs/pub'

module Qiniu
  module RS
    describe Pub do

      before :all do
        @bucket = "test123"
        code, data = Qiniu::RS::RS.mkbucket(@bucket)
        code.should == 200
        puts data.inspect
      end

=begin
      context ".mkbucket" do
        it "should works" do
          code, data = Qiniu::RS::RS.mkbucket(@bucket)
          code.should == 200
          puts data.inspect
        end
      end
=end

      after :all do
        result = Qiniu::RS.drop(@bucket)
        result.should_not be_false
      end

      context ".set_protected" do
        it "should works" do
          code, data = Qiniu::RS::Pub.set_protected(@bucket, 1)
          code.should == 200
          puts data.inspect
        end
      end

      context ".set_separator" do
        it "should works" do
          code, data = Qiniu::RS::Pub.set_separator(@bucket, "-")
          code.should == 200
          puts data.inspect
        end
      end

      context ".set_style" do
        it "should works" do
          code, data = Qiniu::RS::Pub.set_style(@bucket, "small.jpg", "imageMogr/auto-orient/thumbnail/!120x120r/gravity/center/crop/!120x120/quality/80")
          code.should == 200
          puts data.inspect
        end
      end

      context ".unset_style" do
        it "should works" do
          code, data = Qiniu::RS::Pub.unset_style(@bucket, "small.jpg")
          code.should == 200
          puts data.inspect
        end
      end

    end
  end
end
