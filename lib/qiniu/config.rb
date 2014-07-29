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

        DEFAULT_OPTIONS = {
          :user_agent      => 'QiniuRuby/' + Version.to_s + ' ('+RUBY_PLATFORM+')' + ' Ruby/'+ RUBY_VERSION,
          :method          => :post,
          :content_type    => 'application/x-www-form-urlencoded',
          :auth_url        => "https://acc.qbox.me/oauth2/token",
          :rs_host         => "http://rs.qiniu.com",
          :up_host         => "http://upload.qiniu.com",
          :pub_host        => "http://pu.qbox.me:10200",
          :eu_host         => "http://eu.qbox.me",
          :access_key      => "",
          :secret_key      => "",
          :auto_reconnect  => true,
          :max_retry_times => 3,
          :block_size      => 1024*1024*4,
          :chunk_size      => 1024*256,
          :enable_debug    => true,
          :tmpdir          => Dir.tmpdir + File::SEPARATOR + 'QiniuRuby'
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
    end # module Config
end # module Qiniu
