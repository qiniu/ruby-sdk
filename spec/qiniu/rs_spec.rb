# -*- encoding: utf-8 -*-

require 'digest/sha1'
require 'spec_helper'
require 'qiniu/auth'
require 'qiniu/io'
require 'qiniu'

module Qiniu
  module RS
    describe RS do

      before :all do
        @bucket = 'RubySdkTest' + (Time.now.to_i+rand(1000)).to_s
        @key = Digest::SHA1.hexdigest((Time.now.to_i+rand(100)).to_s)
        @key2 = @key + rand(100).to_s
        #@domain = @bucket + '.dn.qbox.me'

        code, data = Qiniu::RS.mkbucket(@bucket)
        puts [code, data].inspect
        code.should == 200
      end

      after :all do
        code, data = Qiniu::RS.drop(@bucket)
        puts [code, data].inspect
        code.should == 200
      end

      context ".put_file" do
        it "should works" do
          code, data = Qiniu::IO.put_file(__FILE__, @bucket, @key, 'application/x-ruby', 'customMeta', true)
          code.should == 200
          puts data.inspect
        end
      end

      context ".buckets" do
        it "should works" do
          code, data = Qiniu::RS.buckets
          code.should == 200
          puts data.inspect
        end
      end

      context ".stat" do
        it "should works" do
          code, data = Qiniu::RS.stat(@bucket, @key)
          code.should == 200
          puts data.inspect
        end
      end

      context ".get" do
        it "should works" do
          code, data = Qiniu::RS.get(@bucket, @key, "rs_spec.rb", 1)
          code.should == 200
          puts data.inspect
        end
      end

      context ".batch" do
        it "should works" do
          code, data = Qiniu::RS.batch("stat", @bucket, [@key])
          code.should == 200
          puts data.inspect
        end
      end

      context ".batch_stat" do
        it "should works" do
          code, data = Qiniu::RS.batch_stat(@bucket, [@key])
          code.should == 200
          puts data.inspect
        end
      end

      context ".batch_get" do
        it "should works" do
          code, data = Qiniu::RS.batch_get(@bucket, [@key])
          code.should == 200
          puts data.inspect
        end
      end

=begin
      context ".batch_copy" do
        it "should works" do
          code, data = Qiniu.batch_copy [@bucket, @key, @bucket, @key2]
          code.should == 200
          puts data.inspect

          #code2, data2 = Qiniu.stat(@bucket, @key2)
          #code2.should == 200
          #puts data2.inspect
        end
      end

      context ".batch_move" do
        it "should works" do
          code, data = Qiniu.batch_move [@bucket, @key, @bucket, @key2]
          code.should == 200
          puts data.inspect

          #code2, data2 = Qiniu.stat(@bucket, @key2)
          #code2.should == 200
          #puts data2.inspect

          code3, data3 = Qiniu.batch_move [@bucket, @key2, @bucket, @key]
          code3.should == 200
          puts data3.inspect
        end
      end
=end

=begin
      context ".publish" do
        it "should works" do
          code, data = Qiniu.publish(@domain, @bucket)
          code.should == 200
          puts data.inspect
        end
      end

      context ".unpublish" do
        it "should works" do
          code, data = Qiniu.unpublish(@domain)
          code.should == 200
          puts data.inspect
        end
      end
=end

      context ".move" do
        it "should works" do
          code, data = Qiniu::RS.move(@bucket, @key, @bucket, @key2)
          code.should == 200
          puts data.inspect

          code2, data2 = Qiniu::RS.stat(@bucket, @key2)
          code2.should == 200
          puts data2.inspect

          code3, data3 = Qiniu::RS.move(@bucket, @key2, @bucket, @key)
          code3.should == 200
          puts data3.inspect
        end
      end

      context ".copy" do
        it "should works" do
          code, data = Qiniu::RS.copy(@bucket, @key, @bucket, @key2)
          code.should == 200
          puts data.inspect

          #code2, data2 = Qiniu.stat(@bucket, @key2)
          #code2.should == 200
          #puts data2.inspect
        end
      end

      context ".delete" do
        it "should works" do
          code, data = Qiniu::RS.delete(@bucket, @key)
          code.should == 200
          puts data.inspect
        end
      end

      context ".drop" do
        it "should works" do
          code, data = Qiniu::RS.drop(@bucket)
          code.should == 200
          puts data.inspect
        end
      end

    end
  end
end
