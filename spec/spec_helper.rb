# -*- encoding: utf-8 -*-

require 'bundler/setup'
require 'qiniu/rs'
require 'rspec'

RSpec.configure do |config|
  config.before :all do
    Qiniu::RS.establish_connection! :access_key => ENV["QINIU_ACCESS_KEY"], :secret_key => ENV["QINIU_SECRET_KEY"]
  end
end
