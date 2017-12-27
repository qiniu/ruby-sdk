# -*- encoding: utf-8 -*-
# vim: sw=2 ts=2

module Qiniu
  module HTTP

    class << self
      public
      def is_response_ok?(http_code)
          return 200 <= http_code && http_code <= 299
      end # is_response_ok?

      def generate_query_string(params)
        if params.is_a?(Hash)
          total_param = params.map { |key, value| %Q(#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s).gsub('+', '%20')}) }
          return total_param.join("&")
        end

        return params
      end # generate_query_string

      def get(url, opts = {})
        ### 配置请求Header
        req_headers = {
          :connection => 'close',
          :accept     => '*/*',
          :user_agent => Config.settings[:user_agent]
        }

        # 优先使用外部Header，覆盖任何特定Header
        if opts[:headers].is_a?(Hash)
          req_headers.merge!(opts[:headers])
        end

        ### 发送请求
        response = RestClient.get(url, req_headers)
        return response.code.to_i, response.body, response.raw_headers
      rescue => e
        Log.logger.warn "#{e.message} => Qiniu::HTTP.get('#{url}')"
        if e.respond_to?(:response) && e.response.respond_to?(:code)
          return e.response.code, e.response.body, e.response.raw_headers
        end
        return nil, nil, nil
      end # get

      API_RESULT_MIMETYPE = 'application/json'

      def api_get(url, opts = {})
        ### 配置请求Header
        headers = {
          :accept => API_RESULT_MIMETYPE
        }

        # 将特定Header混入外部Header中
        if opts[:headers].is_a?(Hash)
          opts[:headers] = opts[:headers].dup.merge!(headers)
        else
          opts[:headers] = headers
        end

        ### 发送请求，然后转换返回值
        resp_code, resp_body, resp_headers = get(url, opts)
        if resp_code.nil?
          return 0, {}, {}
        end

        content_type = resp_headers["content-type"][0]
        unless content_type.nil? || content_type.downcase.index(API_RESULT_MIMETYPE).nil?
          # 如果是JSON格式，则反序列化
          resp_body = Utils.safe_json_parse(resp_body)
        end

        return resp_code, resp_body, resp_headers
      end # api_get

      def post(url, req_body = nil, opts = {})
        ### 配置请求Header
        req_headers = {
          :connection => 'close',
          :accept     => '*/*',
          :user_agent => Config.settings[:user_agent]
        }

        # 优先使用外部Header，覆盖任何特定Header
        if opts[:headers].is_a?(Hash)
          req_headers.merge!(opts[:headers])
        end

        ### 发送请求
        response = RestClient.post(url, req_body, req_headers)
        return response.code.to_i, response.body, response.raw_headers
      rescue => e
        Log.logger.warn "#{e.message} => Qiniu::HTTP.post('#{url}')"
        if e.respond_to?(:response) && e.response.respond_to?(:code)
          return e.response.code, e.response.body, e.response.raw_headers
        end
        return nil, nil, nil
      end # post

      def api_post(url, req_body = nil, opts = {})
        ### 配置请求Header
        headers = {
          :accept => API_RESULT_MIMETYPE
        }

        # 将特定Header混入外部Header中
        if opts[:headers].is_a?(Hash)
          opts[:headers] = opts[:headers].dup.merge!(headers)
        else
          opts[:headers] = headers
        end

        ### 发送请求，然后转换返回值
        resp_code, resp_body, resp_headers = post(url, req_body, opts)
        if resp_code.nil?
          return 0, {}, {}
        end

        content_type = resp_headers["content-type"][0]
        unless content_type.nil? || content_type.downcase.index(API_RESULT_MIMETYPE).nil?
          # 如果是JSON格式，则反序列化
          resp_body = Utils.safe_json_parse(resp_body)
        end

        return resp_code, resp_body, resp_headers
      end # api_post

      def management_post(url, body = '')
        ### 授权并执行管理操作
        return HTTP.api_post(url, body, {
          :headers => { 'Authorization' => 'QBox ' + Auth.generate_acctoken(url, body) }
        })
      end # management_post
    end # class << self

  end # module HTTP
end # module Qiniu
