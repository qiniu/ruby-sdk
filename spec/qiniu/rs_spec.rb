# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs'

module Qiniu
  describe RS do

    before :all do
      @bucket = 'qiniu_rs_test'
      @key = Digest::SHA1.hexdigest Time.now.to_s
      @domain = 'cdn.example.com'
    end

=begin
    context ".login!" do
      it "should works" do
        result = Qiniu::RS.login!("test@qbox.net", "test")
        result.should be_true
      end
    end
=end

    context ".put_auth" do
      it "should works" do
        result = Qiniu::RS.put_auth(10)
        result.should_not be_false
        result.should_not be_empty
        puts result.inspect
      end
    end

    context ".upload" do
      it "should works" do
        put_url = Qiniu::RS.put_auth(10)
        put_url.should_not be_false
        put_url.should_not be_empty
        puts put_url.inspect
        result = Qiniu::RS.upload :url => put_url,
                                  :file =>  __FILE__,
                                  :bucket => @bucket,
                                  :key => @key,
                                  :enable_crc32_check => true
        result.should be_true
      end
    end

    context ".stat" do
      it "should works" do
        result = Qiniu::RS.stat(@bucket, @key)
        result.should_not be_false
        result.should_not be_empty
        puts result.inspect
      end
    end

    context ".get" do
      it "should works" do
        result = Qiniu::RS.get(@bucket, @key, "rs_spec.rb", 10)
        result.should_not be_false
        result.should_not be_empty
        puts result.inspect
      end
    end

    context ".download" do
      it "should works" do
        result = Qiniu::RS.download(@bucket, @key, "rs_spec.rb", 10)
        result.should_not be_false
        result.should_not be_empty
        puts result.inspect
      end
    end

    context ".batch" do
      it "should works" do
        result = Qiniu::RS.batch("stat", @bucket, [@key])
        result.should_not be_false
        result.should_not be_empty
        puts result.inspect
      end
    end

    context ".batch_stat" do
      it "should works" do
        result = Qiniu::RS.batch_stat(@bucket, [@key])
        result.should_not be_false
        result.should_not be_empty
        puts result.inspect
      end
    end

    context ".batch_get" do
      it "should works" do
        result = Qiniu::RS.batch_get(@bucket, [@key])
        result.should_not be_false
        result.should_not be_empty
        puts result.inspect
      end
    end

    context ".batch_download" do
      it "should works" do
        result = Qiniu::RS.batch_download(@bucket, [@key])
        result.should_not be_false
        result.should_not be_empty
        puts result.inspect
      end
    end

    context ".publish" do
      it "should works" do
        result = Qiniu::RS.publish(@domain, @bucket)
        result.should_not be_false
      end
    end

    context ".unpublish" do
      it "should works" do
        result = Qiniu::RS.unpublish(@domain)
        result.should_not be_false
      end
    end

    context ".delete" do
      it "should works" do
        result = Qiniu::RS.delete(@bucket, @key)
        result.should_not be_false
      end
    end

    context ".drop" do
      it "should works" do
        result = Qiniu::RS.drop(@bucket)
        result.should_not be_false
      end
    end

    context ".image_info" do
      it "should works" do
        data = Qiniu::RS.get("test_images", "image_logo_for_test.png")
        data.should_not be_false
        data.should_not be_empty
        puts data.inspect
        result = Qiniu::RS.image_info(data["url"])
        result.should_not be_false
        result.should_not be_empty
        puts result.inspect
      end
    end

  end
end
