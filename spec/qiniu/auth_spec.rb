# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/auth/digest'

module Qiniu
  module RS
    describe Auth do

      before :all do
        @access_key = "iN7NgwM31j4-BZacMjPrOQBs34UG1maYCAQmhdCV"
        @secret_key = "6QTOr2Jg1gcZEWDQXKOGZh5PziC2MCV5KsntT70j"

		@mac = Qiniu::Auth::Digest::Mac.new(@access_key, @secret_key)

		@to_sign = "http://wolfgang.qiniudn.com/down.jpg?e=1373249874"
		@signed = "iN7NgwM31j4-BZacMjPrOQBs34UG1maYCAQmhdCV:vT1lXEttzzPLP4i5T8YVz0AEjCg="
      end

      context ".sign_data" do
		it "should works" do
			token = @mac.sign(@to_sign)
			token.should == @signed
        	puts token.inspect
        end

#        it "should sign in failed when pass a wrong password" do
#          code, data = Qiniu::RS::Auth.exchange_by_password!(@username, "a-wrong-password")
#          code.should == 401
#          data["error_code"].should == 11
#          data["error"].should == "failed_authentication"
#          puts data.inspect
#        end
      end

#      context ".exchange_by_refresh_token" do
#        it "should works" do
#          @refresh_token.should_not be_empty
#          code, data = Qiniu::RS::Auth.exchange_by_refresh_token!(@refresh_token)
#          code.should == 200
#          data["access_token"].should_not be_empty
#          data["refresh_token"].should_not be_empty
#          data["expires_in"].should_not be_zero
#          puts data.inspect
#        end
#      end

    end
  end
end
