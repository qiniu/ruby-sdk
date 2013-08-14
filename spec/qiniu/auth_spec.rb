# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/auth/digest'
require 'qiniu/rs/tokens'

module Qiniu
  module Rs
    describe Auth do

      before :all do
        if ENV['QINIU_ACCESS_KEY'] && ENV['QINIU_SECRET_KEY']
# @gist make_mac
          @access_key = Qiniu::Conf.settings[:access_key]
          @secret_key = Qiniu::Conf.settings[:secret_key]

          @mac = Qiniu::Auth::Digest::Mac.new(@access_key, @secret_key)
# @endgist
        else
          puts 'source test-env.sh'
          exit(1)
        end

		@to_sign = "http://wolfgang.qiniudn.com/down.jpg?e=1373249874"
		@signed = "iN7NgwM31j4-BZacMjPrOQBs34UG1maYCAQmhdCV:vT1lXEttzzPLP4i5T8YVz0AEjCg="

        @bucket = "a"
        @key = "myKey1"

        @put_basic_token = "iN7NgwM31j4-BZacMjPrOQBs34UG1maYCAQmhdCV:1QPEbnl4GhftWXCdfWKa4UCfdKU=:eyJkZWFkbGluZSI6MTM3MzQ1MDQ2Niwic2NvcGUiOiJhOm15S2V5MSJ9"
      end

      context ".sign_data" do
		    it "should works" do
		      token = @mac.sign(@to_sign)
		      token.should == @signed
        	puts token.inspect
        end
      end

=begin
      context ".sign_data" do
        it "should works" do
# @gist downloadUrl
          base_url = Qiniu::Rs.MakeBaseUrl("a.qiniudn.com", "down.jpg")
          url = @mac.make_request(base_url, @mac)
# @endgist
          token.should == @signed
          puts token.inspect
        end
      end
=end

=begin
      context ".upload_token" do
        it "should works" do
          pp = Qiniu::Rs::PutPolicy.new({
              :scope => %Q(#{@bucket}:#{@key}),
              :expires => 1800
            })
          token = pp.token(@mac)
          puts %Q(    #{pp.scope} : token -> #{token})
          token.should == @put_basic_token
        end
      end
=end

    end
  end
end
