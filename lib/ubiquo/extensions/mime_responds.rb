module Ubiquo
  module Extensions
    module MimeResponds
      def self.included base
        base.class_eval do
          class << self
            attr_accessor :default_response_handlers
          end

          class_inheritable_accessor :default_response_handlers
          self.default_response_handlers ||= { }

          include InstanceMethods
          include Formats
          extend ClassMethods

          alias_method_chain :respond_to, :default_format_responses
        end
      end

      module ClassMethods
        def default_format_response_with(format, handler)
          self.default_response_handlers[format.to_sym] = handler
        end
      end

      module InstanceMethods
        def respond_to_with_default_format_responses(*types, &block)
          raise ArgumentError, "respond_to takes either types or a block, never both" unless types.any? ^ block
          block ||= lambda { |responder| types.each { |type| responder.send(type) } }
          responder = ActionController::Base::Responder.new(self)
          block.call(responder)

          avaliable_formats = responder.instance_eval{ @responses.keys.map(&:to_sym) }
          self.default_response_handlers.each_pair do |format, handler|
            unless avaliable_formats.include?(format)
              handler.bind(self).call(responder)
            end
          end

          responder.respond
        end
      end

      module Formats
        def self.included base
          [Js].each do |mod|
            base.send(:include, mod)
          end
        end

        module Js
          ATTRIBUTES_FOR_LABEL = %w{ name title }
          def self.included base
            base.class_eval do
              default_response_handlers[:js] = lambda{ |format|
                set = instance_variable_get("@#{controller_name}") || instance_variable_get("@#{controller_name.singularize}") || []
                object = set.is_a?(Array) ? set.first : set

                attributes = ([:id] <<  ATTRIBUTES_FOR_LABEL.detect{ |attr| object.respond_to?(attr) } ).compact
                hash_results = set.to_json( :only => attributes )

                format.js { render :js => hash_results }
              }
            end
          end
        end
      end
    end
  end
end


