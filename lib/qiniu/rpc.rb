# -*- encoding: utf-8 -*-

require 'uri'
require 'cgi'
require 'json'
require 'zlib'
require 'base64'
require 'rest_client'
require 'hmac-sha1'
require 'qiniu/basic/exceptions'
require 'qiniu/basic/utils'
require 'qiniu/conf'
require 'qiniu/auth/digest'

module Qiniu
	module Rpc

		class Client

			def initialize(host)
				@host = host
				@headers = {:user_agent => Qiniu::Conf.settings[:user_agent]}
			end

			def call(path)
				call_with(path, nil)
			end

			def call_with(path, body, content_type, content_length)
			end

			def post_multipart(path, fields, headers = nil)
				if fields.nil? then
					fields = {}
				end

	        	fields.merge(:multipart => true)
	        	post(path, fields, headers)
			end

			def call_with_form(path, ops)
			end

			def post(path, payload = nil, headers = nil)
				if headers.nil? then
					headers = {}
				end
				headers.merge(@headers)
				url = @host
				url += "/" if path[0].chr != '/' && @host[@host.length - 1].chr != '/'
				url += path
				puts url
	        	RestClient.post(url, payload, headers)
			end

			def get(path, headers = nil)
				if headers.nil? then
					headers = {}
				end
				headers.merge(@headers)
				RestClient.get(host + "/" + path, headers)
			end
		end

      class AuthClient < Client

        include Utils

        attr_accessor :mac

        def initialize(host, mac = nil)
          super(host)
          if mac.nil? then
            @mac = Qiniu::Auth::Digest::Mac.new(Qiniu::Conf.settings[:access_key], Qiniu::Conf.settings[:secret_key])
          else
            @mac = mac
          end
        end        
      end

      class PutClient < AuthClient

        include Utils

        def initialize(host, mac = nil)
          super(host, mac)
        end

        # 执行put操作，调用post_mulitpart()
        # 参数：
        #   1. fields：放入multipart的字段
        def call(fields)
          post_mulitpart("", mp_fields)
        end
      end

      class ManageClient < AuthClient

        include Utils

        def initialize(host, mac = nil)
          super(host, mac)
        end

        # 执行management操作，包括生成AccessToken，构造form body等
        # 参数：
        #   1. path：操作构成的路径。
        #   2. body：管理操作的body（操作的集合）。
        def call(path, query, body)
          token = @mac.generate_access_token(path, query, body)

		  qry_str = path
		  qry_str += "?" + query if !query.nil? && !query.empty?

		  headers = { "Authorization" => "QBox " + token , "Content-Type" => "application/x-www-form-urlencoded" }

          post(qry_str, body, headers)
        end

      end

	end
end
