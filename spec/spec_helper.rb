# -*- encoding: utf-8 -*-

require 'bundler/setup'
require 'qiniu/rs'
require 'rspec'

RSpec.configure do |config|
  config.before :all do
#=begin
    Qiniu::RS.establish_connection! :access_key => "3fPHl_SLkPXdioqI_A8_NGngPWVJhlDk2ktRjogH",
                                    :secret_key => "bXTPMDJrVYRJUiSDRFtFYwycVD_mjXxYWrCYlDHy"
#=end
=begin
    Qiniu::RS.establish_connection! :access_key => "bE21M6FW9V7zAFrBY5psgKOKJQLiBj12qMWTpc57",
                                    :secret_key => "uMo7Nyq_eDK_CuQ8_FYCxoTHQZqjiaPh-cbiKO7L",
                                    :auth_url   => "http://m1.qbox.me:13001/oauth2/token",
                                    :rs_host    => "http://m1.qbox.me:13003",
                                    :io_host    => "http://m1.qbox.me:13004",
                                    :up_host    => "http://m1.qbox.me:13019",
                                    :pub_host   => "http://m1.qbox.me:13012",
                                    :eu_host    => "http://m1.qbox.me:13050"
=end
=begin
    Qiniu::RS.establish_connection! :access_key => "k6N9zXGKUs7UFmJtPXLWOF4idSAgPL4xA6BApBd-",
                                    :secret_key => "p77h4hLERjGPi1Aw4P_G5qHGMKcz1MeSz3CqnYMV",
                                    :auth_url   => "http://127.0.0.1:9100/oauth2/token",
                                    :rs_host    => "http://127.0.0.1:9400",
                                    :io_host    => "http://127.0.0.1:9200",
                                    :up_host    => "http://127.0.0.1:11200",
                                    :pub_host   => "http://127.0.0.1:10200",
                                    :eu_host    => "http://127.0.0.1:15000"
=end
  end
end
