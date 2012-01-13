module Ubiquo
  module RequiredFields
    module Validations

      def self.included(klass)
        klass.send :include, InstanceMethods
        klass.send :alias_method_chain, :validates, :required_fields
      end

      module InstanceMethods
        #
        # Adds field names to required fields.
        #
        def validates_with_required_fields(*attr_names)
          # +options+ is modified inside the original method,
          # so we have to check its value first
          options = attr_names.extract_options!
          validate_presence = options[:presence]

          validates_without_required_fields(*attr_names, options)
          required_fields(*attr_names) if validate_presence
        end
      end
    end
  end
end

