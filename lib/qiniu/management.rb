# -*- encoding: utf-8 -*-
# vim: sw=2 ts=2

require 'qiniu/adt'
require 'qiniu/http'

module Qiniu
    module Storage
      class ListPolicy
        include ADT::Policy

        private
        def initialize(bucket,
                       limit = 1000,
                       prefix = '',
                       delimiter = '')
          @bucket     = bucket
          @limit      = limit
          @prefix     = prefix
          @delimiter  = delimiter
        end # initialize

        public
        PARAMS = {
          # 字符串类型参数
          :bucket     =>  "bucket",
          :prefix     =>  "prefix",
          :delimiter  =>  "delimiter",
          :marker     =>  "marker",

          # 数值类型参数
          :limit      =>  "limit"
        } # PARAMS

        PARAMS.each_pair do |key, fld|
          attr_accessor key
        end

        def params
          return PARAMS
        end # params

        alias :to_s :to_query_string
      end # class ListPolicy

      class << self
        include Utils

        public
        def buckets
          url = Config.settings[:rs_host] + '/buckets'
          return HTTP.management_post(url)
        end # buckets

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

        def fetch(bucket, target_url, key)
          url = Config.fetch_host(bucket) + '/fetch/' + Utils.urlsafe_base64_encode(target_url) + '/to/' + encode_entry_uri(bucket, key)
          return HTTP.management_post(url)
        end # fetch

        def chgm(bucket,key,mine_type)
          url = Config.settings[:rs_host] + _generate_chgm_opstr(bucket,key,mine_type)
          return HTTP.management_post(url)
        end # chgm
        
        def batch_chgm(bucket,keys,mine_type)
          execs = []
          keys.each do |key|
            execs << 'op=' + _generate_chgm_opstr(bucket, key, mine_type) 
          end
          url = Config.settings[:rs_host] + "/batch"
          return HTTP.management_post(url, execs.join("&"))
        end # batch chgm

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
          _batch_cp_or_mv('move', *args)
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

        def list(list_policy)
          url = Config.settings[:rsf_host] + '/list?' + list_policy.to_query_string()

          resp_code, resp_body, resp_headers = HTTP.management_post(url)
          if resp_code == 0 || resp_code > 299 then
            has_more = false
            return resp_code, resp_body, resp_headers, has_more, list_policy
          end

          has_more = (resp_body['marker'].is_a?(String) && resp_body['marker'] != '')
          if has_more then
            new_list_policy = list_policy.clone()
            new_list_policy.marker = resp_body['marker']
          else
            new_list_policy = list_policy
          end

          return resp_code, resp_body, resp_headers, has_more, new_list_policy
        end # list

        private

        def _generate_cp_or_mv_opstr(command, source_bucket, source_key, target_bucket, target_key)
          source_encoded_entry_uri = encode_entry_uri(source_bucket, source_key)
          target_encoded_entry_uri = encode_entry_uri(target_bucket, target_key)
          %Q(/#{command}/#{source_encoded_entry_uri}/#{target_encoded_entry_uri})
        end # _generate_cp_or_mv_opstr

        def _generate_chgm_opstr(bucket,key,mine_type)
          source_encoded_entry_uri = encode_entry_uri(bucket, key)
          target_mine_type = urlsafe_base64_encode "#{mine_type}"
          %Q(/chgm/#{source_encoded_entry_uri}/mime/#{target_mine_type})
        end
        
        def _batch_cp_or_mv(command, *op_args)
          execs = []
          op_args.each do |e|
            execs << 'op=' + _generate_cp_or_mv_opstr(command, e[0], e[1], e[2], e[3]) if e.size == 4
          end
          url = Config.settings[:rs_host] + "/batch"
          return HTTP.management_post(url, execs.join("&"))
        end # _batch_cp_or_mv

      end # class << self
    end # module Storage
end # module Qiniu
