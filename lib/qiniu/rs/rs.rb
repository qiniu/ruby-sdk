# -*- encoding: utf-8 -*-

require "qiniu/auth/digest"
require "qiniu/conf"
require "qiniu/rpc"
require "qiniu/basic/utils"

module Qiniu
  module Rs

      class EntryPath
        attr_accessor :Bucket, :Key
        def initialize (bucket, key)
          @Bucket = bucket
          @Key = key
        end
      end

      class EntryPathPair
        attr_accessor :Src, :Dest
        def initialize (src, dest)
          @Src = src
          @Dest = dest
        end
      end


    class Client

      def initialize(mac = nil)
        @conn = Qiniu::Rpc::ManageClient.new(Qiniu::Conf.settings[:rs_host], mac)
      end

      def Stat(bucket, key)
        return @conn.call(uri_stat(bucket, key), nil, nil)
      end

      def Delete(bucket, key)
        return @conn.call(uri_delete(bucket, key), nil, nil)
      end

      def Move(bucket_src, key_src, bucket_dest, key_dest)
        return @conn.call(uri_move(bucket_src, key_src, bucket_dest, key_dest), nil, nil)
      end

      def Copy(bucket_src, key_src, bucket_dest, key_dest)
        return @conn.call(uri_copy(bucket_src, key_src, bucket_dest, key_dest), nil, nil)
      end

      def BatchStat(entries = [])
        ops = []
        entries.each {|entry|
          ops << 'op=' + uri_stat(entry.Bucket, entry.Key)
        }
        return batch(ops)
      end

      def BatchDelete(entries = [])
        ops = []
        entries.each {|entry|
          ops. << 'op=' + uri_delete(entry.Bucket, entry.Key)
        }
        return batch(ops)
      end

      def BatchMove(entries = [])
        ops = []
        entries.each {|entry|
          ops << 'op=' + uri_move(entry.Src.Bucket, entry.Src.Key, entry.Dest.Bucket, entry.Dest.Key)
        }
        return batch(ops)
      end

      def BatchCopy(entries = [])
        ops = []
        entries.each {|entry|
          ops << 'op=' + uri_copy(entry.Src.Bucket, entry.Src.Key, entry.Dest.Bucket, entry.Dest.Key)
        }
        return batch(ops)
      end

      def List(bucket, marker, limit, prefix)
        return @conn.call(uri_list(bucket, marker, limit, prefix), nil, nil)
      end

      private

      def uri_stat(bucket, key)
        return '/stat/' + Qiniu::Utils.encode_entry_uri(bucket, key)
      end

      def uri_delete(bucket, key)
        return '/delete/' + Qiniu::Utils.encode_entry_uri(bucket, key)
      end

      def uri_move(bucket_src, key_src, bucket_dest, key_dest)
        return '/move/' + Qiniu::Utils.encode_entry_uri(bucket_src, key_src) + '/' + Qiniu::Utils.encode_entry_uri(bucket_dest, key_dest)
      end

      def uri_copy(bucket_src, key_src, bucket_dest, key_dest)
        return '/copy/' + Qiniu::Utils.encode_entry_uri(bucket_src, key_src) + '/' + Qiniu::Utils.encode_entry_uri(bucket_dest, key_dest)
      end

      def batch(ops)
        body = ops.join("&")
        return @conn.call("/batch", nil, body)
      end

      def uri_list(bucket, marker, limit, prefix)
        url = '/list?bucket=' + bucket
        url += '&marker=' + marker unless marker.nil?
        url += '&limit=' + limit unless limit.nil?
        url += '&prefix' + prefix unless prefix.nil?
      end

    end

  end
end
