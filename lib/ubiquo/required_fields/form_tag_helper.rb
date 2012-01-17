module Ubiquo
  module RequiredFields
    module FormTagHelper

      def self.included(klass)
        klass.send :alias_method_chain, :label_tag, :asterisk
      end

      # appends an asterisk to the text if needed
      def label_tag_with_asterisk(name, text = nil, options = {})
        if !text.nil? && options["append_asterisk"] == true
          span_class = Ubiquo::Settings.get(:required_field_class)
          text += "<span class= #{span_class} > * </span>".html_safe
        end
        options.delete("append_asterisk")
        label_tag_without_asterisk(name, text, options)
      end
    end
  end
end
