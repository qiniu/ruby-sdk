# -*- encoding: utf-8 -*-
#
# USAGE WAY 1:
# Qbox::Config.initialize_connect :client_id => "<ClientID>",
#                                 :client_secret => "<ClientSecret>"
#
# USAGE WAY 2:
# Qbox::Config.load "path/to/your_project/config/qiniu.yml"
#

require "qiniu/rs/version"

module Qiniu
  module RS
    module Config
      class << self

        DEFAULT_OPTIONS = {
          :user_agent      => 'Qiniu-RS-Ruby-SDK-' + VERSION + '()',
          :method          => :post,
          :content_type    => 'application/x-www-form-urlencoded',
          :auth_url        => "https://acc.qbox.me/oauth2/token",
          :rs_host         => "http://rs.qbox.me:10100",
          :io_host         => "http://iovip.qbox.me",
          :up_host         => "http://up.qbox.me",
          :pub_host        => "http://pu.qbox.me:10200",
          :eu_host         => "http://eu.qbox.me",
          :client_id       => "a75604760c4da4caaa456c0c5895c061c3065c5a",
          :client_secret   => "75df554a39f58accb7eb293b550fa59618674b7d",
          :access_key      => "",
          :secret_key      => "",
          :auto_reconnect  => true,
          :max_retry_times => 5
        }

        REQUIRED_OPTION_KEYS = [:client_id, :client_secret, :auth_url, :rs_host, :io_host]

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
end
