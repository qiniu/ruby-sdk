# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'fakeweb'
require 'qiniu/rs/utils'

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

      context ".send_request_with" do
        it "should works" do
          FakeWeb.allow_net_connect = false
          FakeWeb.register_uri(:get, "http://docs.qiniutek.com/", :body => {:abc => 123}.to_json)
          res = Utils.send_request_with 'http://docs.qiniutek.com/', nil, :method => :get
          res.should == [200, {"abc" => 123}]
        end

        [400, 500].each do |code|
          context "upstream return http #{code}" do
            it "should raise RestClient::RequestFailed" do
              FakeWeb.allow_net_connect = false
              FakeWeb.register_uri(:get, "http://docs.qiniutek.com/", :status => code)
              lambda {
                res = Utils.send_request_with 'http://docs.qiniutek.com/', nil, :method => :get
              }.should raise_error RestClient::RequestFailed
            end
          end
        end
      end

    end
  end
end
