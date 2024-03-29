# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/abstract'

describe Qiniu::Abstract do
  before(:each) do
    @klass = Class.new do
      include Qiniu::Abstract

      abstract_methods :foo, :bar
    end
  end

  it "raises NotImplementedError" do
    expect { @klass.new.foo }.to raise_error(NotImplementedError)
  end

  it "can be overridden" do
    subclass = Class.new(@klass) do
      def foo
        :overridden
      end
    end

    expect(subclass.new.foo).to eq(:overridden)
  end
end
