# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/auth'

module Qiniu
  module RS
    describe Auth do

      before :all do
        @username = "qboxtest"
        @password = "qboxtest123"

        code, data = Qiniu::RS::Auth.exchange_by_password!(@username, @password)
        code.should == 200
        data.should be_an_instance_of(Hash)
        data["access_token"].should_not be_empty
        data["refresh_token"].should_not be_empty
        data["refresh_token"].should_not be_empty

        @access_token = data["access_token"]
        @refresh_token = data["refresh_token"]
        puts data.inspect
      end

      context ".exchange_by_password" do
        it "should sign in failed when pass a non-existent username" do
          code, data = Qiniu::RS::Auth.exchange_by_password!("a_non_existent_user@example.com", "password")
          code.should == 401
          data["error_code"].should == 11
          data["error"].should == "failed_authentication"
          puts data.inspect
        end

        it "should sign in failed when pass a wrong password" do
          code, data = Qiniu::RS::Auth.exchange_by_password!(@username, "a-wrong-password")
          code.should == 401
          data["error_code"].should == 11
          data["error"].should == "failed_authentication"
          puts data.inspect
        end
      end

      context ".exchange_by_refresh_token" do
        it "should works" do
          @refresh_token.should_not be_empty
          code, data = Qiniu::RS::Auth.exchange_by_refresh_token!(@refresh_token)
          code.should == 200
          data["access_token"].should_not be_empty
          data["refresh_token"].should_not be_empty
          data["expires_in"].should_not be_zero
          puts data.inspect
        end
      end

    end
  end
end
