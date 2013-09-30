# -*- encoding: utf-8 -*-

require "qiniu/conf"
require "qiniu/rpc"

module Qiniu
  module Rsf


    class Client

      def initialize(mac = nil)
        @conn = Qiniu::Rpc::ManageClient.new(Qiniu::Conf.settings[:rsf_host], mac)
      end

      def List(bucket, marker, limit, prefix)
        code, res = @conn.call(uri_list(bucket, marker, limit, prefix), nil, nil)
        begin
          res = JSON.parse(res)
        rescue JSON::ParserError
          res = {:error => JSON::ParserError, :data => res}
        end
        return code, res
      end

      private


      def uri_list(bucket, marker, limit, prefix)
        url = '/list?bucket=' + bucket
        url += '&marker=' + marker unless marker.nil?
        url += '&limit=' + limit.to_s unless limit.nil?
        url += '&prefix' + prefix unless prefix.nil?
        url
      end

    end

  end
end

