module Ubiquo
  module Extensions
    module Proc
      # Alternative method for Proc#bind. This accepts any type of object, not
      # only class instances.
      # Before rails' bind method worked in this way:
      # https://github.com/rails/rails/commit/d32965399ccfa2052a4d52b70db1bae0ca16830b
      def ubind(object)
        block, time = self, Time.now
        object.singleton_class.class_eval do
          method_name = "__bind_#{time.to_i}_#{time.usec}"
          define_method(method_name, &block)
          method = instance_method(method_name)
          remove_method(method_name)
          method
        end.bind(object)
      end
    end
  end
end
