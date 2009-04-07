module Ubiquo
  module RequiredFields
    module FormTagHelper
      
      def self.included(klass)
        klass.send :include, InstanceMethods
        klass.send :alias_method_chain, :label_tag, :asterisk
      end
      
      module InstanceMethods
        def label_tag_with_asterisk(name, text = nil, options = {})
          text += " *" if !text.nil? && options["append_asterisk"] == true
          label_tag_without_asterisk(name, text, options)
        end
      end
    end
  end
end
