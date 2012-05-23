# -*- encoding: utf-8 -*-

module Qiniu
  module RS
    module RS
      class << self
        include Utils

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

        def batch_delete(bucket, keys)
          batch("delete", bucket, keys)
        end

      end
    end
  end
end
