# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/abstract'

describe Qiniu::RS::Abstract do
  before(:each) do
    @klass = Class.new do
      include Qiniu::RS::Abstract

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
