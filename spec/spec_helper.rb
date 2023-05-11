# -*- encoding: utf-8 -*-

require 'bundler/setup'
require 'qiniu'
require 'rspec'
require 'webmock'

if RUBY_ENGINE == 'jruby' && Gem::Version.create(RUBY_VERSION) < Gem::Version::create('2.3.0')
  # Do nothing
else
  require 'simplecov'
  require 'codecov'

  SimpleCov.start
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

RSpec.configure do |config|
  config.before :all do
    Qiniu.establish_connection! :access_key => ENV["QINIU_ACCESS_KEY"], :secret_key => ENV["QINIU_SECRET_KEY"]
  end
  config.before :each, :not_set_ak_sk => true do
    Qiniu.establish_connection! :access_key => nil, :secret_key => nil
  end

  config.order = :defined
end

def make_unique_bucket (bucket)
    "#{bucket}-#{ENV["QINIU_ACCESS_KEY"][0, 8]}-#{Time.now.to_f}"
end # make_unique_bucket

def make_unique_key_in_bucket (key)
    "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}-#{key}-#{Time.now.to_f}"
end # make_unique_key_in_bucket
