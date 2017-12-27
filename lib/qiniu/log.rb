# -*- encoding: utf-8 -*-

require 'logger'

module Qiniu
  module Log
    class << self
      def logger
        @logger ||= Logger.new(STDERR)
      end

      def logger=(logger)
        @logger = logger
      end
    end
  end # module Log
end # module Qiniu
