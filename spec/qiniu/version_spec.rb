# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/version'

describe Qiniu::Version do
  it "should has a VERSION" do
    Qiniu::Version.to_s.should =~ /^\d+\.\d+\.\d+?$/
  end
end
