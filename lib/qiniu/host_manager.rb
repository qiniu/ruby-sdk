require 'thread'
require 'cgi'

module Qiniu
  class BucketIsMissing < RuntimeError; end

  class HostManager
    def initialize(config)
      @config = config
      @mutex = Mutex.new
      @hosts = {}
    end

    def up_host(bucket, opts = {})
      if !multi_region_support?
        "#{extract_protocol(opts)}://up.qiniu.com"
      elsif bucket
        host = hosts(bucket)
        "#{extract_protocol(opts)}://" + host['up']['acc']['main'][0] rescue "#{extract_protocol(opts)}://" + host['up']['src']['main'][0]
      else
        raise BucketIsMissing, 'HostManager#up_host: bucket is required when multi_region is enabled'
      end
    end

    def fetch_host(bucket, opts = {})
      if !multi_region_support?
        "#{extract_protocol(opts)}://iovip.qbox.me"
      elsif bucket
        host = hosts(bucket)
        "#{extract_protocol(opts)}://" + host['io']['acc']['main'][0] rescue "#{extract_protocol(opts)}://" + host['io']['src']['main'][0]
      else
        raise BucketIsMissing, 'HostManager#fetch_host: bucket is required when multi_region is enabled'
      end
    end

    def up_hosts(bucket, opts = {})
      if multi_region_support?
        host = hosts(bucket)['up']
        multi_region_hosts = []
        if host.key?('acc')
          multi_region_hosts | host['acc']['main']
        end
        if host.key?('src')
          multi_region_hosts | host['src']['main']
        end
        return multi_region_hosts
      else
        raise 'HostManager#up_hosts: multi_region must be enabled'
      end
    end

    def global(bucket, opts = {})
      if multi_region_support?
        !!hosts(bucket)['global']
      else
        raise 'HostManager#global: multi_region must be enabled'
      end
    end

    private

    def extract_protocol(opts)
      (opts[:protocol] || @config[:protocol]).to_s
    end

    def multi_region_support?
      @config[:multi_region]
    end

    def hosts(bucket)
      host = read_host(bucket)
      if host
        if host_expired?(host)
          delete_host(bucket)
        else
          return host
        end
      end
      url = @config[:uc_host] + '/v2/query?' + HTTP.generate_query_string(ak: @config[:access_key], bucket: bucket)
      status, body = HTTP.api_get(url)
      if HTTP.is_response_ok?(status)
        Utils.debug("Query #{bucket} hosts Success: #{body}")
        host = body.merge(:time => Time.now)
        write_host(bucket, host)
        host
      else
        Utils.debug("Query #{bucket} hosts Error: #{body}")
        raise "Host query is failed"
      end
    end

    def host_expired?(host)
      host[:time] + host['ttl'] < Time.now
    end

    def read_host(bucket)
      @mutex.synchronize do
        @hosts[bucket]
      end
    end

    def write_host(bucket, host)
      @mutex.synchronize do
        @hosts[bucket] = host
      end
    end

    def delete_host(bucket)
      @mutex.synchronize do
        @hosts.delete(bucket)
      end
    end
  end
end
