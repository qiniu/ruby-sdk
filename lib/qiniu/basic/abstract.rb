# -*- encoding: utf-8 -*-

module Qiniu
  module RS
    module Abstract
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def abstract_methods(*args)
          args.each do |name|
            class_eval <<-END
              def #{name}(*args)
                errmsg = %Q(class \#{self.class.name} must implement abstract method #{self.name}##{name}().)
                raise NotImplementedError.new(errmsg)
              end
            END
          end
        end
      end
    end
  end
end
