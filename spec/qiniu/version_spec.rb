# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/version'

describe Qiniu::Version do
  it "should has a VERSION" do
    expect(Qiniu::Version.to_s).to match(/^\d+\.\d+\.\d+?$/)
  end
end
