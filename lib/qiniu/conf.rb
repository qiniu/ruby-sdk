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
require 'qiniu/version'

module Qiniu
  module Conf

    class << self

      DEFAULT_OPTIONS = {
        :user_agent      => 'Qiniu-RS-Ruby-SDK-' + VERSION.to_s + '()',
        :content_type    => 'application/x-www-form-urlencoded',
        :auth_url        => "https://acc.qbox.me/oauth2/token",
        :rs_host         => "http://rs.qbox.me",
        :io_host         => "http://iovip.qbox.me",
        :up_host         => "http://up.qiniu.com",
        :pub_host        => "http://pu.qbox.me:10200",
        :eu_host         => "http://eu.qbox.me",
        :rsf_host        => "http://rsf.qbox.me",
        :access_key      => "",
        :secret_key      => "",
        :auto_reconnect  => true,
        :max_retry_times => 3,
        :block_size      => 1024*1024*4,
        :chunk_size      => 1024*256,
        :enable_debug    => true,
        :tmpdir          => Dir.tmpdir + File::SEPARATOR + 'Qiniu-RS-Ruby-SDK'
      }

      REQUIRED_OPTION_KEYS = [:access_key, :secret_key]

      attr_reader :settings, :default_params

      def load config_file
        if File.exist?(config_file)
          config_options = YAML.load_file(config_file)
          initialize_connect(config_options)
        else
          raise MissingConfError, config_file
        end
      end

      def initialize_connect options = {}
        @settings = DEFAULT_OPTIONS.merge(options)
        REQUIRED_OPTION_KEYS.each do |opt|
          raise MissingArgsError, [opt] unless @settings.has_key?(opt)
        end
      end

    end
  end
end
