# -*- encoding: utf-8 -*-

require 'digest/sha1'
require 'spec_helper'
require 'qiniu/rs'
require 'qiniu/rs/exceptions'

module Qiniu
  describe RS do

    before :all do
      @bucket = 'qiniu_rs_test'
      @key = Digest::SHA1.hexdigest Time.now.to_s
      @domain = 'qiniu-rs-test.dn.qbox.me'

      result = Qiniu::RS.mkbucket(@bucket)
      result.should_not be_false

      @test_image_bucket = 'test_images_12345'
      result2 = Qiniu::RS.mkbucket(@test_image_bucket)
      puts result2.inspect
      result2.should be_true

      @test_image_key = 'image_logo_for_test.png'
      local_file = File.expand_path('./rs/' + @test_image_key, File.dirname(__FILE__))
      puts local_file.inspect
      upopts = {:scope => @test_image_bucket, :expires_in => 3600, :customer => "awhy.xu@gmail.com"}
      uptoken = Qiniu::RS.generate_upload_token(upopts)
      data = Qiniu::RS.upload_file :uptoken => uptoken, :file => local_file, :bucket => @test_image_bucket, :key => @test_image_key
      puts data.inspect
    end

    after :all do
      result = Qiniu::RS.drop(@bucket)
      puts result.inspect
      result.should_not be_false

      result2 = Qiniu::RS.drop(@test_image_bucket)
      puts result2.inspect
      result2.should_not be_false
    end

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
        result = Qiniu::RS.set_separator(@bucket, "-")
        result.should_not be_false
        puts result.inspect
      end
    end

    context ".set_style" do
      it "should works" do
        result = Qiniu::RS.set_style(@bucket, "small.jpg", "imageMogr/auto-orient/thumbnail/!120x120r/gravity/center/crop/!120x120/quality/80")
        result.should_not be_false
        puts result.inspect
      end
    end

    context ".unset_style" do
      it "should works" do
        result = Qiniu::RS.unset_style(@bucket, "small.jpg")
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

    context ".upload_file" do
      it "should works" do
        uptoken_opts = {:scope => @bucket, :escape => 0}
        upload_opts = {
          :uptoken => Qiniu::RS.generate_upload_token(uptoken_opts),
          :file => __FILE__,
          :bucket => @bucket,
          :key => @key,
          :enable_crc32_check => true
        }
        result = Qiniu::RS.upload_file(upload_opts)
        result.should_not be_false
        puts result.inspect
      end

      it "should raise MissingArgsError" do
        uptoken_opts = {:scope => @bucket, :escape => 0}
        upload_opts = {
          :uptoken => Qiniu::RS.generate_upload_token(uptoken_opts),
          :file => __FILE__,
          :key => @key,
          :enable_crc32_check => true
        }
        lambda { Qiniu::RS.upload_file(upload_opts) }.should raise_error(RS::MissingArgsError)
      end

      it "should raise NoSuchFileError" do
        uptoken_opts = {:scope => @bucket, :escape => 0}
        upload_opts = {
          :uptoken => Qiniu::RS.generate_upload_token(uptoken_opts),
          :file => 'no_this_file',
          :bucket => @bucket,
          :key => @key,
          :enable_crc32_check => true
        }
        lambda { Qiniu::RS.upload_file(upload_opts) }.should raise_error(RS::NoSuchFileError)
      end
    end

    context ".resumable_upload_file" do
      it "should works" do
        # generate bigfile for testing
        localfile = "test_bigfile"
        File.open(localfile, "w"){|f| 5242888.times{f.write(Random.rand(9).to_s)}}
        key = Digest::SHA1.hexdigest(localfile+Time.now.to_s)
        # generate the upload token
        uptoken_opts = {:scope => @bucket, :expires_in => 3600, :customer => "awhy.xu@gmail.com", :escape => 0}
        uptoken = Qiniu::RS.generate_upload_token(uptoken_opts)
        # uploading
        upload_opts = {
            :uptoken => uptoken,
            :file => localfile,
            :bucket => @bucket,
            :key => key
        }
        #uploading
        result1 = Qiniu::RS.upload_file(upload_opts)
        #drop the bigfile
        File.unlink(localfile) if File.exists?(localfile)
        #expect
        puts result1.inspect
        result1.should_not be_false
        result1.should_not be_empty
        #stat
        result2 = Qiniu::RS.stat(@bucket, key)
        puts result2.inspect
        result2.should_not be_false
        #delete
        result3 = Qiniu::RS.delete(@bucket, key)
        puts result3.inspect
        result3.should_not be_false
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
        result = Qiniu::RS.mkbucket(dest_bucket)
        result.should_not be_false

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
        result2 = Qiniu::RS.image_mogrify_save_as(dest_bucket, dest_key, src_img_url, mogrify_options)
        result2.should_not be_false
        result2.should_not be_empty
        puts result2.inspect
      end
    end

    context ".generate_upload_token" do
      it "should works" do
        data = Qiniu::RS.generate_upload_token({:scope => 'test_bucket', :expires_in => 3600, :escape => 0})
        data.should_not be_empty
        puts data.inspect
      end
    end

  end
end
