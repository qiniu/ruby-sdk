# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/version'

describe Qiniu::RS::Version do
  it "should has a VERSION" do
    Qiniu::RS::Version.to_s.should =~ /^\d+\.\d+\.\d+?$/
  end
end
