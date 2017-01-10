# -*- encoding: utf-8 -*-

require 'digest/sha1'
require 'spec_helper'
require 'qiniu'
require 'qiniu/exceptions'

module Qiniu
  describe Qiniu do

    before :all do
      @bucket = 'rubysdk'

      @test_image_bucket = @bucket

      @key = Digest::SHA1.hexdigest Time.now.to_s
      @key = make_unique_key_in_bucket(@key)

      @key2 = @key + rand(100).to_s
      #@domain = @bucket + '.dn.qbox.me'

      @test_image_key = 'image_logo_for_test.png'
      local_file = File.expand_path('./' + @test_image_key, File.dirname(__FILE__))
      puts local_file.inspect
      upopts = {:scope => @test_image_bucket, :expires_in => 3600, :customer => "why404@gmail.com"}
      uptoken = Qiniu.generate_upload_token(upopts)
      data = Qiniu.upload_file :uptoken => uptoken, :file => local_file, :bucket => @test_image_bucket, :key => @test_image_key
      puts data.inspect
    end

    after :all do
    end

    context ".buckets" do
      it "should works" do
        result = Qiniu.buckets
        expect(result).to_not be_empty
        puts result.inspect
      end
    end

    context ".set_protected" do
      it "should works" do
        result = Qiniu.set_protected(@bucket, 1)
        expect(result).to eq(true)
        puts result.inspect
      end
    end

    context ".set_separator" do
      it "should works" do
        result = Qiniu.set_separator(@bucket, "-")
        expect(result).to eq(true)
        puts result.inspect
      end
    end

    context ".set_style" do
      it "should works" do
        result = Qiniu.set_style(@bucket, "small.jpg", "imageMogr/auto-orient/thumbnail/!120x120r/gravity/center/crop/!120x120/quality/80")
        expect(result).to eq(true)
        puts result.inspect
      end
    end

    context ".unset_style" do
      it "should works" do
        result = Qiniu.unset_style(@bucket, "small.jpg")
        expect(result).to eq(true)
        puts result.inspect
      end
    end

    context ".upload_file" do
      it "should works" do
        uptoken_opts = {:scope => @bucket, :escape => 0}
        upload_opts = {
          :uptoken => Qiniu.generate_upload_token(uptoken_opts),
          :file => __FILE__,
          :bucket => @bucket,
          :key => @key,
          :enable_crc32_check => true
        }
        result = Qiniu.upload_file(upload_opts)
        expect(result).to_not be_empty
        puts result.inspect
      end

      it "should raise MissingArgsError" do
        uptoken_opts = {:scope => @bucket, :escape => 0}
        upload_opts = {
          :uptoken => Qiniu.generate_upload_token(uptoken_opts),
          :file => __FILE__,
          :key => @key,
          :enable_crc32_check => true
        }
        lambda { Qiniu.upload_file(upload_opts) }.should raise_error(MissingArgsError)
      end

      it "should raise NoSuchFileError" do
        uptoken_opts = {:scope => @bucket, :escape => 0}
        upload_opts = {
          :uptoken => Qiniu.generate_upload_token(uptoken_opts),
          :file => 'no_this_file',
          :bucket => @bucket,
          :key => @key,
          :enable_crc32_check => true
        }
        lambda { Qiniu.upload_file(upload_opts) }.should raise_error(NoSuchFileError)
      end
    end

    context ".resumable_upload_file" do
      it "should works" do
        # generate bigfile for testing
        localfile = "test_bigfile"
        File.open(localfile, "w"){|f| 5242888.times{f.write(rand(9).to_s)}}
        key = Digest::SHA1.hexdigest(localfile+Time.now.to_s)
        # generate the upload token
        uptoken_opts = {:scope => @bucket, :expires_in => 3600, :customer => "why404@gmail.com", :escape => 0}
        uptoken = Qiniu.generate_upload_token(uptoken_opts)
        # uploading
        upload_opts = {
            :uptoken => uptoken,
            :file => localfile,
            :bucket => @bucket,
            :key => key
        }
        #uploading
        result1 = Qiniu.upload_file(upload_opts)
        #drop the bigfile
        File.unlink(localfile) if File.exists?(localfile)
        #expect
        puts result1.inspect
        expect(result1).to_not be_empty
        #stat
        result2 = Qiniu.stat(@bucket, key)
        puts result2.inspect
        expect(result2).to_not be_empty
        #delete
        result3 = Qiniu.delete(@bucket, key)
        puts result3.inspect
        expect(result3).to eq(true)
      end
    end

    context ".stat" do
      it "should works" do
        result = Qiniu.stat(@bucket, @key)
        expect(result).to_not be_empty
        puts result.inspect
      end
    end

    context ".batch" do
      it "should works" do
        result = Qiniu.batch("stat", @bucket, [@key])
        expect(result).to_not be_empty
        puts result.inspect
      end
    end

    context ".batch_stat" do
      it "should works" do
        result = Qiniu.batch_stat(@bucket, [@key])
        expect(result).to_not be_empty
        puts result.inspect
      end
    end

=begin
    context ".batch_copy" do
      it "should works" do
        result = Qiniu.batch_copy [@bucket, @key, @bucket, @key2]
        result.should_not be_falsey

        #result2 = Qiniu.stat(@bucket, @key2)
        #result2.should_not be_falsey
      end
    end

    context ".batch_move" do
      it "should works" do
        result = Qiniu.batch_move [@bucket, @key, @bucket, @key2]
        result.should_not be_falsey

        #result2 = Qiniu.stat(@bucket, @key2)
        #result2.should_not be_falsey

        result3 = Qiniu.batch_move [@bucket, @key2, @bucket, @key]
        result3.should_not be_falsey
      end
    end
=end

    context ".move" do
      it "should works" do
        result = Qiniu.move(@bucket, @key, @bucket, @key2)
        expect(result).to eq(true)

        result2 = Qiniu.stat(@bucket, @key2)
        expect(result2).to_not be_empty

        result3 = Qiniu.move(@bucket, @key2, @bucket, @key)
        expect(result3).to eq(true)
      end
    end

    context ".copy" do
      it "should works" do
        result = Qiniu.copy(@bucket, @key, @bucket, @key2)
        expect(result).to eq(true)

        result3 = Qiniu.delete(@bucket, @key2)
        expect(result3).to eq(true)
      end
    end

    context ".delete" do
      it "should works" do
        result = Qiniu.delete(@bucket, @key)
        expect(result).to eq(true)
      end
    end

    # context ".image_info" do
    #   it "should works" do
    #     pending 'This function cannot work for private bucket file'
    #     code, domains, = Qiniu::Storage.domains(@test_image_bucket)
    #     code.should be 200
    #     domains.should_not be_empty
    #     domain = domains.first['domain']
    #     url = "http://#{domain}/#{@test_image_key}"

    #     result = Qiniu.image_info(url)
    #     expect(result).to_not be_falsey
    #     puts result.inspect
    #   end
    # end

    # context ".image_mogrify_save_as" do
    #   it "should works" do
    #     pending 'This function cannot work for private bucket file'
    #     code, domains, = Qiniu::Storage.domains(@test_image_bucket)
    #     code.should be 200
    #     domains.should_not be_empty
    #     domain = domains.first['domain']
    #     src_img_url = "http://#{domain}/#{@test_image_key}"

    #     dest_key = "cropped-" + @test_image_key
    #     mogrify_options = {
    #       :thumbnail => "!120x120>",
    #       :gravity => "center",
    #       :crop => "!120x120a0a0",
    #       :quality => 85,
    #       :rotate => 45,
    #       :format => "jpg",
    #       :auto_orient => true
    #     }
    #     result2 = Qiniu.image_mogrify_save_as(@test_image_bucket, dest_key, src_img_url, mogrify_options)
    #     expect(result2).to_not be_falsey
    #     puts result2.inspect
    #   end
    # end

    context ".generate_upload_token" do
      it "should works" do
        data = Qiniu.generate_upload_token({:scope => @bucket, :expires_in => 3600, :escape => 0})
        data.should_not be_empty
        puts data.inspect
        data.split(":").length.should == 3
      end
    end

    context ".generate_download_token" do
      it "should works" do
        data = Qiniu.generate_download_token({:expires_in => 1, :pattern => 'http://*.dn.qbox.me/*'})
        data.should_not be_empty
        puts data.inspect
        data.split(":").length.should == 3
      end
    end

  end
end # module Qiniu
