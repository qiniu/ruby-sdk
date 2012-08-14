# -*- encoding: utf-8 -*-

require 'bundler/setup'
require 'qiniu/rs'
require 'rspec'

RSpec.configure do |config|
  config.before :all do
=begin
    Qiniu::RS.establish_connection! :access_key => "3fPHl_SLkPXdioqI_A8_NGngPWVJhlDk2ktRjogH",
                                    :secret_key => "bXTPMDJrVYRJUiSDRFtFYwycVD_mjXxYWrCYlDHy"
=end
#=begin
    Qiniu::RS.establish_connection! :access_key => "bE21M6FW9V7zAFrBY5psgKOKJQLiBj12qMWTpc57",
                                    :secret_key => "uMo7Nyq_eDK_CuQ8_FYCxoTHQZqjiaPh-cbiKO7L",
                                    :auth_url   => "http://m1.qbox.me:13001/oauth2/token",
                                    :rs_host    => "http://m1.qbox.me:13003",
                                    :io_host    => "http://m1.qbox.me:13004",
                                    :up_host    => "http://m1.qbox.me:13019",
                                    :pub_host   => "http://m1.qbox.me:13012",
                                    :eu_host    => "http://m1.qbox.me:13050"
#=end
  end
end
