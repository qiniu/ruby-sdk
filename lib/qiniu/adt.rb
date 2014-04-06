# -*- encoding: utf-8 -*-
# vim: sw=2 ts=2

require 'uri'

module Qiniu
  module ADT
    
    class ApiSpecification
      public
      def to_str; return ""; end
    end # class ApiSpecification

    module Policy
      public
      def to_json
        args = {}

        self.params.each_pair do |key, fld|
          val = self.__send__(key)
          if !val.nil? then
            args[fld] = val
          end
        end

        return args.to_json
      end # to_json

      def to_query_string
        args = []

        self.params.each_pair do |key, fld|
          val = self.__send__(key)
          if !val.nil? then
            new_fld = CGI.escape(fld.to_s)
            new_val = CGI.escape(val.to_s).gsub('+', '%20')
            args.push("#{new_fld}=#{new_val}")
          end
        end

        return args.join("&")
      end # to_query_string
    end # module Policy

  end # module ADT
end # module Qiniu
