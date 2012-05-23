# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/version'

describe Qiniu::RS do
  it "should has a VERSION" do
    Qiniu::RS::VERSION.should =~ /^\d+\.\d+\.\d+?$/
  end
end
