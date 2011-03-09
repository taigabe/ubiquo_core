module Ubiquo
  module Extensions
    # This is a hook module to include anything to any installed class
    # Allows to circumvent the cache_classes problem for classes not in plugins
    module Loader
      mattr_accessor :extensions, :methods

      self.extensions ||= {}
      self.methods = %w{include extend helper}

      # Returns true if the that symbol has scheduled extensions to be included
      def self.has_extensions?(sym)
        extensions[sym.to_s]
      end

      def self.extensions_for(sym)
        Module.new{
          def self.included(recipient)
            Loader.methods.each do |method|
              Array(Loader.extensions[self.name.split('::').last][method]).each do |k|
                  recipient.send(method, k)
              end
            end
          end
        }
      end

      methods.each do |method|

        self.class_eval <<-EOS
          # Schedules the inclusion of +klass+ inside +recipient+
          # Use this instead of sending direct includes, extends or helpers
          def self.append_#{method}(recipient, klass)            # def self.append_include(recipient, klass)
            extensions[recipient.to_s] ||= {}                    #   extensions[recipient.to_s] ||= {}
            extensions[recipient.to_s]["#{method}"] ||= []       #   extensions[recipient.to_s]["include"] ||= []
            extensions[recipient.to_s]["#{method}"] << klass     #   extensions[recipient.to_s]["include"] << klass
          end                                                    # end
        EOS
      end

    end
  end
end
