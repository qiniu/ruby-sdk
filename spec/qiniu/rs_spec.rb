# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs'

module Qiniu
  describe RS do

    before :all do
      @bucket = 'qiniu_rs_test'
      @key = Digest::SHA1.hexdigest Time.now.to_s
      @domain = 'cdn.example.com'

      @test_image_bucket = 'test_images_12345'
      @test_image_key = 'image_logo_for_test.png'

      result = Qiniu::RS.mkbucket(@bucket)
      result.should_not be_false
    end

=begin
    context ".login!" do
      it "should works" do
        result = Qiniu::RS.login!("test@qbox.net", "test")
        result.should be_true
      end
    end
=end

    context ".buckets" do
      it "should works" do
        result = Qiniu::RS.buckets
        result.should_not be_false
        puts result.inspect
      end
    end

    context ".set_protected" do
      it "should works" do
        result = Qiniu::RS.set_protected(@bucket, 1)
        result.should_not be_false
        puts result.inspect
      end
    end

    context ".set_separator" do
      it "should works" do
        result = Qiniu::RS::Pub.set_separator(@bucket, "-")
        result.should_not be_false
        puts result.inspect
      end
    end

    context ".set_style" do
      it "should works" do
        result = Qiniu::RS::Pub.set_style(@bucket, "small.jpg", "imageMogr/auto-orient/thumbnail/!120x120r/gravity/center/crop/!120x120/quality/80")
        result.should_not be_false
        puts result.inspect
      end
    end

    context ".unstyle" do
      it "should works" do
        result = Qiniu::RS::Pub.unstyle(@bucket, "small.jpg")
        result.should_not be_false
        puts result.inspect
      end
    end

    context ".set_watermark" do
      it "should works" do
        options = {
          :text => "Powered by QiniuRS"
        }
        result = Qiniu::RS.set_watermark(1, options)
        result.should_not be_false
        puts result.inspect
      end
    end

    context ".get_watermark" do
      it "should works" do
        result = Qiniu::RS.get_watermark(1)
        result.should_not be_false
        puts result.inspect
      end
    end

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
                                  :mime_type => 'application/x-ruby',
                                  :enable_crc32_check => true
        result.should be_true
      end
    end

    context ".put_file" do
      it "should works" do
        result = Qiniu::RS.put_file :file =>  __FILE__,
                                    :bucket => @bucket,
                                    :key => @key,
                                    :mime_type => 'application/x-ruby',
                                    :enable_crc32_check => true
        result.should be_true
      end
    end

    context ".upload_with_token" do
      it "should works" do
        uptoken_opts = {:scope => @bucket, :expires_in => 3600, :callback_url => "http://localhost:4567"}
        upload_opts = {
          :uptoken => Qiniu::RS.generate_upload_token(uptoken_opts),
          :file => __FILE__,
          :bucket => @bucket,
          :key => @key,
          :enable_crc32_check => true
        }
        result = Qiniu::RS.upload_with_token(upload_opts)
        result.should_not be_false
        puts result.inspect
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
        data = Qiniu::RS.get(@test_image_bucket, @test_image_key)
        data.should_not be_false
        data.should_not be_empty
        puts data.inspect
        result = Qiniu::RS.image_info(data["url"])
        result.should_not be_false
        result.should_not be_empty
        puts result.inspect
      end
    end

    context ".image_exif" do
      it "should works" do
        data = Qiniu::RS.get(@test_image_bucket, @test_image_key)
        data.should_not be_false
        data.should_not be_empty
        puts data.inspect
        result = Qiniu::RS.image_exif(data["url"])
        puts result.inspect
      end
    end

    context ".image_mogrify_save_as" do
      it "should works" do
        data = Qiniu::RS.get(@test_image_bucket, @test_image_key)
        data.should_not be_false
        data.should_not be_empty
        puts data.inspect

        dest_bucket = "test_thumbnails_bucket"
        dest_key = "cropped-" + @test_image_key
        src_img_url = data["url"]
        mogrify_options = {
          :thumbnail => "!120x120>",
          :gravity => "center",
          :crop => "!120x120a0a0",
          :quality => 85,
          :rotate => 45,
          :format => "jpg",
          :auto_orient => true
        }
        result = Qiniu::RS.image_mogrify_save_as(dest_bucket, dest_key, src_img_url, mogrify_options)
        result.should_not be_false
        result.should_not be_empty
        puts result.inspect
      end
    end

    context ".generate_upload_token" do
      it "should works" do
        data = Qiniu::RS.generate_upload_token({:scope => 'test_bucket', :expires_in => 3600})
        data.should_not be_empty
        puts data.inspect
      end
    end

  end
end
