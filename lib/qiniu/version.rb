# -*- encoding: utf-8 -*-

module Qiniu
    module Version
      MAJOR = 6
      MINOR = 2
      PATCH = 4
      # Returns a version string by joining <tt>MAJOR</tt>, <tt>MINOR</tt>, and <tt>PATCH</tt> with <tt>'.'</tt>
      #
      # Example
      #
      #   Version.to_s # '1.0.2'
      def self.to_s
        [MAJOR, MINOR, PATCH].join('.')
      end
    end # Version
end # module Qiniu
