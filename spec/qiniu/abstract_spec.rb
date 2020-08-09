# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/abstract'
require 'simplecov'
SimpleCov.start
require 'codecov'
SimpleCov.formatter = SimpleCov::Formatter::Codecov

describe Qiniu::Abstract do
  before(:each) do
    @klass = Class.new do
      include Qiniu::Abstract

      abstract_methods :foo, :bar
    end
  end

  it "raises NotImplementedError" do
    proc {
      @klass.new.foo
    }.should raise_error(NotImplementedError)
  end

  it "can be overridden" do
    subclass = Class.new(@klass) do
      def foo
        :overridden
      end
    end

    subclass.new.foo.should == :overridden
  end
end
