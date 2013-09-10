# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'fakeweb'
require 'qiniu/basic/utils'

module Qiniu
  module RS
    describe Utils do
      before :all do
        Struct.new("Response", :code, :body)
      end

      after :each do
        FakeWeb.clean_registry
        FakeWeb.allow_net_connect = true
      end

      context "safe_json_parse" do
        it "should works" do
          Utils.safe_json_parse('{"foo": "bar"}').should == {"foo" => "bar"}
          Utils.safe_json_parse('{}').should == {}
        end
      end

    end
  end
end
