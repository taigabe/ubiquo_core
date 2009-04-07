module Ubiquo
  module RequiredFields
    module ActiveRecord
      
      def self.included(klass)
        klass.send :include, InstanceMethods
        klass.send :extend, ClassMethods
      end
      
      module InstanceMethods
        def required_fields
          self.class.required_fields
        end
      end
      
      module ClassMethods
        def required_fields(*fields)
           @required_fields ||= if self.superclass.respond_to?(:required_fields)
            self.superclass.required_fields
          else
            []
          end
          @required_fields += fields
          @required_fields
        end
      end
      
    end
  end
end
