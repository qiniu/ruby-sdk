# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/utils'

module Qiniu
  module RS
    describe Utils do
      include WebMock::API

      after :each do
        WebMock.disable!
      end

      context "safe_json_parse" do
        it "should works" do
          Utils.safe_json_parse('{"foo": "bar"}').should eq({"foo" => "bar"})
          Utils.safe_json_parse('{}').should == {}
        end
      end

      context ".send_request_with" do
        it "should works" do
          WebMock.enable!
          stub_request(:get, "develoepr.qiniu.com/").to_return(body: {abc: 123}.to_json)
          res = Utils.send_request_with 'http://develoepr.qiniu.com/', nil, :method => :get
          res.should == [200, {"abc" => 123}, {}]
        end

        [400, 500].each do |code|
          context "upstream return http #{code}" do
            it "should raise RestClient::RequestFailed" do
              WebMock.enable!
              stub_request(:get, "develoepr.qiniu.com/").to_return(status: code)
              expect do
                Utils.send_request_with 'http://develoepr.qiniu.com/', nil, :method => :get
              end.to raise_error RestClient::RequestFailed
            end
          end
        end
      end

    end
  end
end
