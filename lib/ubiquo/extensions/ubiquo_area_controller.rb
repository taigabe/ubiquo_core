module Ubiquo
  module Extensions
    # This is a hook module to include anything to UbiquoAreaController
    module UbiquoAreaController
      def self.included(klass)
        if @include_after
          @include_after.each{|k| klass.send(:include, k)}
        end
        if @extend_after
          @extend_after.each{|k| klass.send(:extend, k)}
        end
        if @helper_after
          @helper_after.each{|k| klass.send(:helper, k)}
        end
      end
      
      # Includes a klass inside UbiquoAreaController
      # Use this instead of sending direct includes
      def self.append_include(klass)
        @include_after ||= []
        @include_after << klass
      end

      # Extends UbiquoAreaController with klass
      # Use this instead of sending direct extends
      def self.append_extend(klass)
        @extend_after ||= []
        @extend_after << klass
      end

      # Adds klass as a helper inside UbiquoAreaController
      # Use this instead of sending direct helper calls
      def self.append_helper(klass)
        @helper_after ||= []
        @helper_after << klass
      end
    end
  end
end
