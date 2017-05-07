# -*- encoding: utf-8 -*-

require 'bundler/setup'
require 'qiniu'
require 'rspec'
require 'webmock'

RSpec.configure do |config|
  config.before :all do
    Qiniu.establish_connection! :access_key => ENV["QINIU_ACCESS_KEY"] || 'QWYn5TFQsLLU1pL5MFEmX3s5DmHdUThav9WyOWOm',
                                :secret_key => ENV["QINIU_SECRET_KEY"] || 'Bxckh6FA-Fbs9Yt3i3cbKVK22UPBmAOHJcL95pGz'
  end
  config.before :each, :not_set_ak_sk => true do
    Qiniu.establish_connection! :access_key => nil, :secret_key => nil
  end

  config.order = :defined
end

def make_unique_bucket (bucket)
    bucket + "-" + ENV["QINIU_ACCESS_KEY"][0, 8]
end # make_unique_bucket

def make_unique_key_in_bucket (key)
    "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}-" + key
end # make_unique_key_in_bucket
