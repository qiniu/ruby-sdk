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
        return @conn.call(uri_list(bucket, marker, limit, prefix), nil, nil)
      end

      private


      def uri_list(bucket, marker, limit, prefix)
        url = '/list?bucket=' + bucket
        url += '&marker=' + marker unless marker.nil?
        url += '&limit=' + limit unless limit.nil?
        url += '&prefix' + prefix unless prefix.nil?
        url
      end

    end

  end
end

