# -*- encoding: utf-8 -*-

require 'bundler/setup'
require 'qiniu/rs'
require 'rspec'

RSpec.configure do |config|
  config.before :all do
    Qiniu::RS.establish_connection! :access_key => "3fPHl_SLkPXdioqI_A8_NGngPWVJhlDk2ktRjogH",
                                    :secret_key => "bXTPMDJrVYRJUiSDRFtFYwycVD_mjXxYWrCYlDHy"
  end
end
