# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/tokens/qbox_token'

module Qiniu
  module RS
    describe QboxToken do
      before :all do
        @qbox_token = QboxToken.new(:url => 'www.qiniu.com?key1=value1',
                                    :params => { :key2 => 'value2' })
        @qbox_token.access_key = 'access_key'
        @qbox_token.secret_key = 'secret_key'
      end

      context "#generate_token" do
        it "should generate token" do
          expect(@qbox_token.generate_token).not_to be_empty
        end
      end

      context "#generate_signature" do
        it "should generate signature" do
          expect(@qbox_token.generate_signature).to eq("www.qiniu.com?key1=value1\nkey2=value2")
        end
      end
    end
  end
end
