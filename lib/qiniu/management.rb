# -*- encoding: utf-8 -*-
# vim: sw=2 ts=2

require 'qiniu/http'

module Qiniu
    module Storage
      class << self
        include Utils

        public
        def buckets
          url = Config.settings[:rs_host] + '/buckets'
          return HTTP.management_post(url)
        end # buckets

        PRIVATE_BUCKET = 0
        PUBLIC_BUCKET  = 1

        def mkbucket(bucket_name, is_public = PUBLIC_BUCKET)
          url = Config.settings[:rs_host] + '/mkbucket2/' + bucket_name + '/public/' + is_public.to_s
          return HTTP.management_post(url)
        end # mkbucket

        def make_a_private_bucket(bucket_name)
          return mkbucket(bucket_name, PRIVATE_BUCKET)
        end # make_a_private_bucket

        def make_a_public_bucket(bucket_name)
          return mkbucket(bucket_name, PUBLIC_BUCKET)
        end # make_a_public_bucket

        def stat(bucket, key)
          url = Config.settings[:rs_host] + '/stat/' + encode_entry_uri(bucket, key)
          return HTTP.management_post(url)
        end # stat

        def get(bucket, key, save_as = nil, expires_in = nil, version = nil)
          url = Config.settings[:rs_host] + '/get/' + encode_entry_uri(bucket, key)
          url += '/base/' + version unless version.nil?
          url += '/attName/' + Utils.urlsafe_base64_encode(save_as) unless save_as.nil?
          url += '/expires/' + expires_in.to_s if !expires_in.nil? && expires_in > 0
          return HTTP.management_post(url)
        end # get

        def copy(source_bucket, source_key, target_bucket, target_key)
          uri = _generate_cp_or_mv_opstr('copy', source_bucket, source_key, target_bucket, target_key)
          url = Config.settings[:rs_host] + uri
          return HTTP.management_post(url)
        end # copy

        def move(source_bucket, source_key, target_bucket, target_key)
          uri = _generate_cp_or_mv_opstr('move', source_bucket, source_key, target_bucket, target_key)
          url = Config.settings[:rs_host] + uri
          return HTTP.management_post(url)
        end # move

        def delete(bucket, key)
          url = Config.settings[:rs_host] + '/delete/' + encode_entry_uri(bucket, key)
          return HTTP.management_post(url)
        end # delete

        def publish(domain, bucket)
          encoded_domain = Utils.urlsafe_base64_encode(domain)
          url = Config.settings[:rs_host] + "/publish/#{encoded_domain}/from/#{bucket}"
          return HTTP.management_post(url)
        end # publish

        def unpublish(domain)
          encoded_domain = Utils.urlsafe_base64_encode(domain)
          url = Config.settings[:rs_host] + "/unpublish/#{encoded_domain}"
          return HTTP.management_post(url)
        end # unpublish

        def drop(bucket)
          url = Config.settings[:rs_host] + "/drop/#{bucket}"
          return HTTP.management_post(url)
        end # drop

        def batch(command, bucket, keys)
          execs = []
          keys.each do |key|
            encoded_uri = encode_entry_uri(bucket, key)
            execs << "op=/#{command}/#{encoded_uri}"
          end
          url = Config.settings[:rs_host] + "/batch"
          return HTTP.management_post(url, execs.join("&"))
        end # batch

        def batch_get(bucket, keys)
          batch("get", bucket, keys)
        end # batch_get

        def batch_stat(bucket, keys)
          batch("stat", bucket, keys)
        end # batch_stat

        def batch_copy(*args)
          _batch_cp_or_mv('copy', args)
        end # batch_copy

        def batch_move(*args)
          _batch_cp_or_mv('move', args)
        end # batch_move

        def batch_delete(bucket, keys)
          batch("delete", bucket, keys)
        end # batch_delete

        def save_as(bucket, key, source_url, op_params_string)
          encoded_uri = encode_entry_uri(bucket, key)
          save_as_string = '/save-as/' + encoded_uri
          new_url = source_url + '?' + op_params_string + save_as_string
          return HTTP.management_post(new_url)
        end # save_as

        def image_mogrify_save_as(bucket, key, source_image_url, options)
          mogrify_params_string = Fop::Image.generate_mogrify_params_string(options)
          save_as(bucket, key, source_image_url, mogrify_params_string)
        end # image_mogrify_save_as

        private

        def _generate_cp_or_mv_opstr(command, source_bucket, source_key, target_bucket, target_key)
          source_encoded_entry_uri = encode_entry_uri(source_bucket, source_key)
          target_encoded_entry_uri = encode_entry_uri(target_bucket, target_key)
          %Q(/#{command}/#{source_encoded_entry_uri}/#{target_encoded_entry_uri})
        end # _generate_cp_or_mv_opstr

        def _batch_cp_or_mv(command, *op_args)
          execs = []
          op_args.each do |e| 
            execs << 'op=' + _generate_cp_or_mv_opstr(command, e[0], e[1], e[2], e[3]) if e.size == 4
          end 
          url = Config.settings[:rs_host] + "/batch"
          return HTTP.management_post(url, execs.join("&"))
        end # _batch_cp_or_mv
      end
    end # module Storage
end # module Qiniu
