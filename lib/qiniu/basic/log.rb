# -*- encoding: utf-8 -*-

require 'logger'

module Qiniu
  module RS
    module Log
      class << self
        attr_accessor :logger

        def logger
          @logger ||= Logger.new(STDERR)
        end
      end
    end
  end
end
