# -*- encoding: utf-8 -*-
require 'qiniu/version'
require 'qiniu/conf'
require 'qiniu/basic/exceptions'
require 'qiniu/basic/utils'
require 'qiniu/auth/digest'
require 'qiniu/io'
require 'qiniu/rs/rs'
require 'qiniu/rs/tokens'


module Qiniu
  class << self

    StatusOK = 200

    attr_accessor :access_key, :secret_key

    def establish_connection! opts = {}
      Qiniu::Conf.initialize_connect opts
    end

    def setup
      yield self
      Qiniu::Conf.initialize_connect access_key: @access_key, secret_key: @secret_key
    end

  end
end
