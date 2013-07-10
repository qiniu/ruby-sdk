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
			@access_key = "iN7NgwM31j4-BZacMjPrOQBs34UG1maYCAQmhdCV"
			@secret_key = "6QTOr2Jg1gcZEWDQXKOGZh5PziC2MCV5KsntT70j"
			@mac = Qiniu::Auth::Digest::Mac.new(@access_key, @secret_key)

			@rs_cli = Qiniu::Rs::Client.new(@mac)

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

			@file_path = "toupload.jpg"
		end

=begin
		after :all do
		result = Qiniu::RS.drop(@bucket)
		puts result.inspect
		result.should_not be_false
		end
=end

		context ".upload_data" do
			it "should works" do
				pe = Qiniu::Io::PutExtra.new
				pp = Qiniu::Rs::PutPolicy.new({ :scope => @bucket1, :expires => 1800 })
				token = pp.token(@mac)
				file_data = File.new(@file_path, 'r')
				code, res = Qiniu::Io.Put(token, @to_del_key, file_data, pe)
				puts %Q(     result: #{code.inspect}, #{puts res.inspect})
				code.should == 200
			end
		end

		context ".upload_file" do
			it "should works" do
				pe = Qiniu::Io::PutExtra.new
				pp = Qiniu::Rs::PutPolicy.new({ :scope => @bucket1, :expires => 1800 })
				token = pp.token(@mac)
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
				code, res = @rs_cli.Stat(@bucket1, @to_del_key)
				puts %Q(    result: #{@bucket1}:#{@to_del_key} -> #{code}, #{res})
				code.should == 200
			end
		end

		context ".copy" do
			it "should works" do
				code, res = @rs_cli.Copy(@bucket1, @to_del_key, @bucket1, @to_copy_key)
				puts %Q(    copy #{@bucket1}:#{@to_del_key} to #{@bucket2}:#{@to_copy_key} -> #{code}, #{res})
				code.should == 200
			end
		end

		context ".move" do
			it "should works" do
				code, res = @rs_cli.Copy(@bucket1, @to_copy_key, @bucket1, @to_move_key)
				puts %Q(    move #{@bucket1}:#{@to_copy_key} to #{@bucket2}:#{@to_move_key} -> #{code}, #{res})
				code.should == 200
			end
		end

		context ".delete" do
			it "should workds" do
				code, res = @rs_cli.Delete(@bucket1, @to_del_key)
				puts %Q(    delete #{@bucket1}:#{@to_del_key} -> #{code}, #{res})
				code.should == 200

				code, res = @rs_cli.Delete(@bucket1, @to_move_key)
				puts %Q(    delete #{@bucket1}:#{@to_move_key} -> #{code}, #{res})
				code.should == 200
			end
		end

		context ".batch_stat" do
			it "should works" do
				to_stat = []
				@keys.each do | key |
					to_stat << Qiniu::Rs::EntryPath.new(@bucket1, key)
				end
				code, res = @rs_cli.BatchStat(to_stat)
				puts %Q(    result: #{code}, #{res})
				code.should == 200
			end
		end

		context ".batch_copy" do
			it "should works" do
				to_copy = []
				i = 0
				while i < @keys.length do
					to_copy << Qiniu::Rs::EntryPathPair.new(
						Qiniu::Rs::EntryPath.new(@bucket1, @keys[i]),
						Qiniu::Rs::EntryPath.new(@bucket2, @copy_keys[i]))
					i += 1
				end
				code, res = @rs_cli.BatchCopy(to_copy)
				puts %Q(    result: #{code}, #{res})
				code.should == 200
			end
		end

		context ".batch_move" do
			it "should works" do
				to_move = []
				i = 0
				while i < @copy_keys.length do
					to_move << Qiniu::Rs::EntryPathPair.new(
						Qiniu::Rs::EntryPath.new(@bucket1, @copy_keys[i]),
						Qiniu::Rs::EntryPath.new(@bucket2, @move_keys[i]))
					i += 1
				end
				code, res = @rs_cli.BatchMove(to_move)
				puts %Q(    result: #{code}, #{res})
				code.should == 200
			end
		end

		context ".batch_delete" do
			it "should works" do
				to_del = []
				@keys.each do  | key |
					to_del << Qiniu::Rs::EntryPath.new(@bucket1, key)
				end
				@move_keys.each do | key |
					to_del << Qiniu::Rs::EntryPath.new(@bucket1, key)
				end

				code, res = @rs_cli.BatchDelete(to_del)
				puts %Q(    result: #{code}, #{res})
				code.should == 200
			end
		end
	end
end
