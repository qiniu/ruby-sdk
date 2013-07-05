# -*- encoding: utf-8 -*-

require 'uri'
require 'cgi'
require 'json'
require 'zlib'
require 'base64'
require 'rest_client'
require 'hmac-sha1'
require 'qiniu/rs/exceptions'

module Qiniu
	module RPC

		class Client

			def initialize(host)
				@host = host
				@headers = {:user_agent => Config.settings[:user_agent]}
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
	        	RestClient.post(host + "/" + path, playload, headers)
			end

			def get(path, headers = nil)
				if headers.nil? then
					headers = {}
				end
				headers.merge(@headers)
				RestClient.get(host + "/" + path, headers)
			end
		end

	end
end