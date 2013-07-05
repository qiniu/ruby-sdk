# -*- encoding: utf-8 -*-

require 'mime/types'
require 'digest/sha1'
require 'qiniu/rs/exceptions'
require 'qiniu/auth/digest'

module qiniu
	module io

      class PutExtra

        attr_accessor :Params, :MimeType, :Crc32, :CheckCrc

        def initialize
          @Params = {}          #用户自定义参数，{"x:<name>" => <value>}，参数名以x:开头
          @MimeType = ''
          @Crc32 = 0
          @CheckCrc = 0
      end

      class PutRet

        attr_accessor :Hash, :Key

      end

      class << self

        include Utils

        #上传文件对象：
        # 参数：
        #   1. uptoken：upload token
        #   2. key：待上传的key
        #   3. data：上传的数据，需要File对象
        #   4. extra：PutExtra对象，包含用户自定义参数
        def Put(uptoken, key, data, extra = nil)
          if extra.nil? then
            extra = PutExtra.new()
          end

          fields = {}

          if extra.CheckCrc != 0 then
            fields.merge({ :crc32 => extra.Crc32 })
          end

          if !key.nil? then
            fields.merge({ :key => key })
          end

          if data.nil? then
            raise "Invalid 'data' parameter. "
          end

          fields.merge({ :file => data })

          if token.nil? then
            raise "Invalid parameter 'put_policy'."
          end

          fields.merge(extra.Params)

          return digest.PutClient.new(Config.settings[:up_host]).call(fields)
        end

        def PutFile(uptoken, key, localfile, extra)
          if extra.CheckCrc == 1 then
            extra.Crc32 = crc32checksum(localfile)
          end

          data = File.new(localfile, 'rb')
          return Put(uptoken, key, data, extra)
        end

      end

	end
end
