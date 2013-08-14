# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'qiniu/rs/rs'
require 'qiniu/basic/exceptions'
require 'digest/sha1'
require 'qiniu/auth/digest'
require 'qiniu/io'
require 'qiniu/rs/tokens'
require 'qiniu/basic/utils'

module Qiniu
  describe Rs do

    before :all do
      if ENV['QINIU_ACCESS_KEY'] && ENV['QINIU_SECRET_KEY']
# @gist make_mac
        @access_key = Qiniu::Conf.settings[:access_key]
        @secret_key = Qiniu::Conf.settings[:secret_key]

        @mac = Qiniu::Auth::Digest::Mac.new(@access_key, @secret_key)
# @endgist
      else
        puts 'source test-env.sh'
        exit(1)
      end

# @gist make_rs_cli
			@rs_cli = Qiniu::Rs::Client.new(@mac)
# @endgist

			@bucket1 = "a"
			@bucket2 = "a"

			srand(Time.now.to_i)

			@to_del_key = Digest::SHA1.hexdigest(rand(100000).to_s)
			@to_copy_key = Digest::SHA1.hexdigest(rand(100000).to_s)
			@to_move_key = Digest::SHA1.hexdigest(rand(100000).to_s)

			@keys = [
				Digest::SHA1.hexdigest(rand(100000).to_s),
				Digest::SHA1.hexdigest(rand(100000).to_s),
				Digest::SHA1.hexdigest(rand(100000).to_s)
			]
			@copy_keys = [
				Digest::SHA1.hexdigest(rand(100000).to_s),
				Digest::SHA1.hexdigest(rand(100000).to_s),
				Digest::SHA1.hexdigest(rand(100000).to_s)
			]
			@move_keys = [
				Digest::SHA1.hexdigest(rand(100000).to_s),
				Digest::SHA1.hexdigest(rand(100000).to_s),
				Digest::SHA1.hexdigest(rand(100000).to_s)
			]

			@file_path = "spec/fixtures/toupload.jpg"
		end

		context ".upload_data" do
			it "should works" do
# @gist upload
				pe = Qiniu::Io::PutExtra.new
				pp = Qiniu::Rs::PutPolicy.new({ :scope => @bucket1, :expires => 1800 })
				token = pp.token(@mac)
				file_data = File.new(@file_path, 'r')
				code, res = Qiniu::Io.Put(token, @to_del_key, file_data, pe)
# @endgist
				puts %Q(     result: #{code.inspect}, #{puts res.inspect})
				code.should == 200
			end
		end

		context ".upload_file" do
			it "should works" do
				pe = Qiniu::Io::PutExtra.new
# @gist uptoken
				pp = Qiniu::Rs::PutPolicy.new({ :scope => @bucket1, :expires => 1800 })
				token = pp.token(@mac)
# @endgist
				code, res = Qiniu::Io.PutFile(token, @keys[0], @file_path, pe)
				puts %Q(    result: #{@keys[0].inspect} => #{code.inspect}, #{res.inspect})
				code.should == 200

			end
		end

		context ".upload_data_crc" do
			it "should works" do
				pe = Qiniu::Io::PutExtra.new
				pp = Qiniu::Rs::PutPolicy.new({ :scope => @bucket1, :expires => 1800 })
				token = pp.token(@mac)
				file_data = File.new(@file_path, 'r')
				pe.Crc32 = Qiniu::Utils.crc32checksum(@file_path)
				pe.CheckCrc = 1
				code, res = Qiniu::Io.Put(token, @keys[1], file_data, pe)
				puts %Q(    result: #{@keys[1].inspect} => #{code.inspect}, #{res.inspect})
				code.should == 200
			end
		end

		context ".upload_file_crc" do
			it "should works" do
				pe = Qiniu::Io::PutExtra.new
				pp = Qiniu::Rs::PutPolicy.new({ :scope => @bucket1, :expires => 1800 })
				token = pp.token(@mac)
				pe.CheckCrc = 1
				code, res = Qiniu::Io.PutFile(token, @keys[2], @file_path, pe)
				puts %Q(    result: #{@keys[2].inspect} => #{code}, #{res})
				code.should == 200
			end
		end

		context ".stat" do
			it "should works" do
# @gist stat
				code, res = @rs_cli.Stat(@bucket1, @to_del_key)
# @endgist
				puts %Q(    result: #{@bucket1}:#{@to_del_key} -> #{code}, #{res})
				code.should == 200
			end
		end

		context ".copy" do
			it "should works" do
# @gist copy
				code, res = @rs_cli.Copy(@bucket1, @to_del_key, @bucket1, @to_copy_key)
# @endgist
				puts %Q(    copy #{@bucket1}:#{@to_del_key} to #{@bucket2}:#{@to_copy_key} -> #{code}, #{res})
				code.should == 200
			end
		end

		context ".move" do
			it "should works" do
# @gist move
				code, res = @rs_cli.Copy(@bucket1, @to_copy_key, @bucket1, @to_move_key)
# @endgist
				puts %Q(    move #{@bucket1}:#{@to_copy_key} to #{@bucket2}:#{@to_move_key} -> #{code}, #{res})
				code.should == 200
			end
		end

		context ".delete" do
			it "should workds" do
# @gist delete
				code, res = @rs_cli.Delete(@bucket1, @to_del_key)
# @endgist
				puts %Q(    delete #{@bucket1}:#{@to_del_key} -> #{code}, #{res})
				code.should == 200

				code, res = @rs_cli.Delete(@bucket1, @to_move_key)
				puts %Q(    delete #{@bucket1}:#{@to_move_key} -> #{code}, #{res})
				code.should == 200
			end
		end

		context ".batch_stat" do
			it "should works" do
# @gist batch_stat
				to_stat = []
				@keys.each do | key |
					to_stat << Qiniu::Rs::EntryPath.new(@bucket1, key)
				end
				code, res = @rs_cli.BatchStat(to_stat)
# @endgist
				puts %Q(    result: #{code}, #{res})
				code.should == 200
			end
		end

		context ".batch_copy" do
			it "should works" do
# @gist batch_copy
				to_copy = []
				i = 0
				while i < @keys.length do
					to_copy << Qiniu::Rs::EntryPathPair.new(
						Qiniu::Rs::EntryPath.new(@bucket1, @keys[i]),
						Qiniu::Rs::EntryPath.new(@bucket2, @copy_keys[i]))
					i += 1
				end
				code, res = @rs_cli.BatchCopy(to_copy)
# @endgist
				puts %Q(    result: #{code}, #{res})
				code.should == 200
			end
		end

		context ".batch_move" do
			it "should works" do
# @gist batch_move
				to_move = []
				i = 0
				while i < @copy_keys.length do
					to_move << Qiniu::Rs::EntryPathPair.new(
						Qiniu::Rs::EntryPath.new(@bucket1, @copy_keys[i]),
						Qiniu::Rs::EntryPath.new(@bucket2, @move_keys[i]))
					i += 1
				end
				code, res = @rs_cli.BatchMove(to_move)
# @endgist
				puts %Q(    result: #{code}, #{res})
				code.should == 200
			end
		end

		context ".batch_delete" do
			it "should works" do
# @gist batch_del
				to_del = []
				@keys.each do  | key |
					to_del << Qiniu::Rs::EntryPath.new(@bucket1, key)
				end
				@move_keys.each do | key |
					to_del << Qiniu::Rs::EntryPath.new(@bucket1, key)
				end

				code, res = @rs_cli.BatchDelete(to_del)
# @endgist
				puts %Q(    result: #{code}, #{res})
				code.should == 200
			end
		end
	end
end
