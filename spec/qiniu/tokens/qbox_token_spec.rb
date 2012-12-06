# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/tokens/qbox_token'

module Qiniu
  module RS
    describe QboxToken do
      before :all do
        @qbox_token = QboxToken.new(:url => 'www.qiniutek.com?key1=value1',
                                    :params => { :key2 => 'value2' })
        @qbox_token.access_key = 'access_key'
        @qbox_token.secret_key = 'secret_key'
      end

      context "#generate_token" do
        it "should generate token" do
          @qbox_token.generate_token.should_not be_empty
        end
      end

      context "#generate_signature" do
        it "should generate signature" do
          @qbox_token.generate_signature.should == "www.qiniutek.com?key1=value1\nkey2=value2"
        end
      end
    end
  end
end
