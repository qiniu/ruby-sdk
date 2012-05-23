# -*- encoding: utf-8 -*-

require 'bundler/setup'
require 'qiniu/rs'
require 'rspec'

RSpec.configure do |config|
  config.before :all do
    Qiniu::RS.establish_connection! :client_id     => "abcd0c7edcdf914228ed8aa7c6cee2f2bc6155e2",
                                    :client_secret => "fc9ef8b171a74e197b17f85ba23799860ddf3b9c"
  end
end
