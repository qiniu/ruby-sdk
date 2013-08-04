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

      def establish_connection!(opts = {})
        Qiniu::Conf.initialize_connect opts
      end

	end
end
