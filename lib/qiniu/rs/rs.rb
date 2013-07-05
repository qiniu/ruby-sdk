# -*- encoding: utf-8 -*-

require "qiniu/auth/digest"

module qiniu
  module rs

      class EntryPath
        attr_accessor :Bucket, :Key
      end

      class EntryPathPair
        attr_accessor :Src, :Dest
      end

      class BatchItemRet
        attr_accessor :Error, :Code
      end

      class BatchStatItemRet
        attr_accessor :Data, :Error, :Code
      end



    class Client

      def initialize(mac = nil)
        @conn = Digest.ManageClient(Config.settings[:rs_host], mac)
      end

      def Stat(bucket, key)
        return @conn.call(uri_stat(bucket, key))
      end

      def Delete(bucket, key)
        return @conn.call(uri_delete(bucket, key))
      end

      def Move(bucket_src, key_src, bucket_dest, key_dest)
        return @conn.call(uri_move(bucket_src, key_src, bucket_dest, key_dest))
      end

      def Copy(bucket_src, key_src, bucket_dest, key_dest)
        return @conn.call(uri_copy(bucket_src, key_src, bucket_dest, key_dest))
      end

      def BatchStat(entries = [])
        ops = []
        entries.each do {|entry|
          ops.append(uri_stat(entry[:bucket], entry[:key]))
        }
        return batch(ops)
      end

      def BatchDelete(entries = [])
        ops = []
        entries.each do {|entry|
          ops.append(uri_delete(entry[:bucket], entry[:key]))
        }
        return batch(ops)
      end

      def BatchMove(entries = [])
        ops = []
        entries.each do {|entry|
          ops.append(uri_move(entry[:bucket], entry[:key]))
        }
        return batch(ops)
      end

      def BatchCopy(entries = [])
        ops = []
        entries.each do {|entry|
          ops.append(uri_copy(entry[:bucket], entry[:key]))
        }
        return batch(ops)
      end

      private

      def uri_stat(bucket, key)
        return '/stat/' + encode_entry_uri(bucket, key)
      end

      def uri_delete(bucket, key)
        return '/delete/' + encode_entry_uri(bucket, key)
      end

      def uri_move(bucket_src, key_src, bucket_dest, key_dest)
        return '/move/' + encode_entry_uri(bucket_src, key_src) + '/' + encode_entry_uri(bucket_dest, key_dest)
      end

      def uri_copy(bucket_src, key_src, bucket_dest, key_dest)
        return '/copy/' + encode_entry_uri(bucket_src, key_src) + '/' + encode_entry_uri(bucket_dest, key_dest)
      end

      def batch(ops)
        body = ops.join("&")
        return @conn.call("/batch", nil, body)
      end

    end

=begin

      class << self
        include Utils

        def buckets
          Auth.request Config.settings[:rs_host] + '/buckets'
        end

        def mkbucket(bucket_name)
          Auth.request Config.settings[:rs_host] + '/mkbucket/' + bucket_name
        end

        def stat(bucket, key)
          Auth.request Config.settings[:rs_host] + '/stat/' + encode_entry_uri(bucket, key)
        end

        def get(bucket, key, save_as = nil, expires_in = nil, version = nil)
          url = Config.settings[:rs_host] + '/get/' + encode_entry_uri(bucket, key)
          url += '/base/' + version unless version.nil?
          url += '/attName/' + Utils.urlsafe_base64_encode(save_as) unless save_as.nil?
          url += '/expires/' + expires_in.to_s if !expires_in.nil? && expires_in > 0
          Auth.request url
        end

        def copy(source_bucket, source_key, target_bucket, target_key)
          uri = _generate_cp_or_mv_opstr('copy', source_bucket, source_key, target_bucket, target_key)
          Auth.request Config.settings[:rs_host] + uri
        end

        def move(source_bucket, source_key, target_bucket, target_key)
          uri = _generate_cp_or_mv_opstr('move', source_bucket, source_key, target_bucket, target_key)
          Auth.request Config.settings[:rs_host] + uri
        end

        def delete(bucket, key)
          Auth.request Config.settings[:rs_host] + '/delete/' + encode_entry_uri(bucket, key)
        end

        def publish(domain, bucket)
          encoded_domain = Utils.urlsafe_base64_encode(domain)
          Auth.request Config.settings[:rs_host] + "/publish/#{encoded_domain}/from/#{bucket}"
        end

        def unpublish(domain)
          encoded_domain = Utils.urlsafe_base64_encode(domain)
          Auth.request Config.settings[:rs_host] + "/unpublish/#{encoded_domain}"
        end

        def drop(bucket)
          Auth.request Config.settings[:rs_host] + "/drop/#{bucket}"
        end

        def batch(command, bucket, keys)
          execs = []
          keys.each do |key|
            encoded_uri = encode_entry_uri(bucket, key)
            execs << "op=/#{command}/#{encoded_uri}"
          end
          Auth.request Config.settings[:rs_host] + "/batch?" + execs.join("&")
        end

        def batch_get(bucket, keys)
          batch("get", bucket, keys)
        end

        def batch_stat(bucket, keys)
          batch("stat", bucket, keys)
        end

        def batch_copy(*args)
          _batch_cp_or_mv('copy', args)
        end

        def batch_move(*args)
          _batch_cp_or_mv('move', args)
        end

        def batch_delete(bucket, keys)
          batch("delete", bucket, keys)
        end

        def save_as(bucket, key, source_url, op_params_string)
          encoded_uri = encode_entry_uri(bucket, key)
          save_as_string = '/save-as/' + encoded_uri
          new_url = source_url + '?' + op_params_string + save_as_string
          Auth.request new_url
        end

        def image_mogrify_save_as(bucket, key, source_image_url, options)
          mogrify_params_string = Image.generate_mogrify_params_string(options)
          save_as(bucket, key, source_image_url, mogrify_params_string)
        end

        private

        def _generate_cp_or_mv_opstr(command, source_bucket, source_key, target_bucket, target_key)
          source_encoded_entry_uri = encode_entry_uri(source_bucket, source_key)
          target_encoded_entry_uri = encode_entry_uri(target_bucket, target_key)
          %Q(/#{command}/#{source_encoded_entry_uri}/#{target_encoded_entry_uri})
        end

        def _batch_cp_or_mv(command, *op_args)
          execs = []
          op_args.each do |e|
            execs << 'op=' + _generate_cp_or_mv_opstr(command, e[0], e[1], e[2], e[3]) if e.size == 4
          end
          Auth.request Config.settings[:rs_host] + "/batch?" + execs.join("&")
        end

      end
=end


  end
end
