# -*- encoding: utf-8 -*-

require 'bundler/setup'
require 'qiniu/rs'
require 'rspec'

RSpec.configure do |config|
  config.before :all do
    Qiniu::RS.establish_connection! :access_key => "iN7NgwM31j4-BZacMjPrOQBs34UG1maYCAQmhdCV",
                                    :secret_key => "6QTOr2Jg1gcZEWDQXKOGZh5PziC2MCV5KsntT70j"
  end
end
