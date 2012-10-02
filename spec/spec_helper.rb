# -*- encoding: utf-8 -*-

require 'bundler/setup'
require 'qiniu/rs'
require 'rspec'

RSpec.configure do |config|
  config.before :all do
=begin
    Qiniu::RS.establish_connection! :access_key => "dFX_wMGVrRzwdWaraW-Qe5ZCDT-kcSmIAGKQOkXh",
                                    :secret_key => "VllxxDfkn_h2ZIqeKYTnHJiN4LVODfDBlJHy_KsW",
                                    :auth_url   => "http://m1.qbox.me:13001/oauth2/token",
                                    :rs_host    => "http://m1.qbox.me:13003",
                                    :io_host    => "http://m1.qbox.me:13004",
                                    :up_host    => "http://m1.qbox.me:13019",
                                    :pub_host   => "http://m1.qbox.me:13012",
                                    :eu_host    => "http://m1.qbox.me:13050"
=end

    Qiniu::RS.establish_connection! :access_key => "aPoWOtE9EFca1fLxFCtlkeZAOV7aADVMTLdSydmr",
                                    :secret_key => "L3ShtjCQTCagVCDPfHJoOix7JO_o3qHz3ScyflUG"
  end
end
