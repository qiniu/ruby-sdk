# -*- encoding: utf-8 -*-
#
# USAGE WAY 1:
# Qbox::Config.initialize_connect :client_id => "<ClientID>",
#                                 :client_secret => "<ClientSecret>"
#
# USAGE WAY 2:
# Qbox::Config.load "path/to/your_project/config/qiniu.yml"
#

require 'tmpdir'

module Qiniu
  module Config
    class << self
      attr_reader :settings, :default_params, :host_manager

      def load config_file
        if File.exist?(config_file)
          config_options = YAML.load_file(config_file)
          config_options.symbolize_keys!
          initialize_connect(config_options)
        else
          raise MissingConfError, config_file
        end
      end

      def initialize_connect options = {}
        options = if options[:protocol] == :https
                    https_options.merge(options)
                  else
                    http_options.merge(options)
                  end
        @settings = default_options.merge(options)
        required_options_keys.each do |opt|
          raise MissingArgsError, [opt] unless @settings.has_key?(opt)
        end
        @host_manager = HostManager.new(@settings)
        nil
      end

      def initialize_connect_https options = {}
        initialize_connect(options.merge(:protocol => :https))
      end

      def switch_to_http
        @settings.merge!(http_options)
      end

      def switch_to_https
        @settings.merge!(https_options)
      end

      def up_host(bucket, opts = {})
        @settings[:up_host] || @host_manager.up_host(bucket, opts)
      end

      def fetch_host(bucket, opts = {})
        @settings[:fetch_host] || @host_manager.fetch_host(bucket, opts)
      end

      private

      def default_options
        {
          :user_agent      => 'QiniuRuby/' + Version.to_s + ' ('+RUBY_PLATFORM+')' + ' Ruby/'+ RUBY_VERSION,
          :method          => :post,
          :content_type    => 'application/x-www-form-urlencoded',
          :auth_url        => "https://acc.qbox.me/oauth2/token",
          :access_key      => "",
          :secret_key      => "",
          :auto_reconnect  => true,
          :max_retry_times => 3,
          :block_size      => 1024*1024*4,
          :chunk_size      => 1024*256,
          :enable_debug    => true,
          :tmpdir          => Dir.tmpdir + File::SEPARATOR + 'QiniuRuby',
          :multi_region    => true
        }.freeze
      end

      def http_options
        {
          :rs_host          => "http://rs.qiniu.com",
          :rsf_host         => "http://rsf.qbox.me",
          :pub_host         => "http://pu.qbox.me:10200",
          :eu_host          => "http://eu.qbox.me",
          :uc_host          => "http://uc.qbox.me",
          :api_host         => "http://api.qiniu.com",
          :protocol => :http
        }.freeze
      end

      def https_options
        {
          :rs_host         => "https://rs.qbox.me",
          :rsf_host        => "https://rsf.qbox.me",
          :pub_host        => "https://pu.qbox.me",
          :eu_host         => "https://eu.qbox.me",
          :uc_host         => "https://uc.qbox.me",
          :api_host        => "https://api.qiniu.com",
          :protocol => :https
        }.freeze
      end

      def required_options_keys
        [:access_key, :secret_key].freeze
      end
    end
  end # module Config
end # module Qiniu
