module Ubiquo
  module Helpers

    # Form Builder that allows to dry our ubiquo forms. It is used by
    # #ubiquo_for_for, but can be used with:
    #
    #   form_for( @actor, :builder => Ubiquo::Helpers::UbiquoFormBuider )
    #
    # How to add methods from the plugins?
    #   the media_selector for instance has to:
    #   1. Add the methods to the global form helper as usual
    #   2. Update UbiquoFormBuilder attributes
    #

    class UbiquoFormBuilder < ActionView::Helpers::FormBuilder

      cattr_accessor :default_tag_options, :enabled, :groups_configuration

      helpers = field_helpers + %w{date_select datetime_select time_select} +
        %w{collection_select select country_select time_zone_select}

      # TODO: integrate relation_selector to this. It now decides the format
      # depending on the type of selector is used (checkbox or select tags)
      ubiquo_helpers = %w{}

      # Dont decorate these
      helpers -= %w{hidden_field label fields_for}
      
      Ubiquo::Config.context(:ubiquo_form_builder) do |context|
        self.default_tag_options = context.get(:default_tag_options)
        self.groups_configuration = context.get(:groups_configuration)
      end

      # Enabled by default
      self.enabled = true 

      # Overwrites the method given by +name+ with Module#define_method to add
      # a label before the tag and group the result in a div.
      # +tag_options+ allows to set the default tag options for +name+.
      #
      # This is usually defined in initializers but can be overwritten here.
      #
      # Specific tag options that are managed in this function are:
      #   +translatable+: used to say that the field is translatable. It adds the required
      #     markup to use it. It accepts boolean or a string that will be rendered on the field
      #   +description+: expects a string that will be shown around the field to
      #     describe the meaning of the field.
      #   +label+: the text that the label will show or the full options passed
      #     to the #label method.
      #   +label_at_bottom+: positions the label after the input
      #   +label_as_legend+: renders the label as legend of the wrapping fieldset
      #   +group+: accepts group configurations. See #group method doc.
      #

      def self.initialize_method( name, tag_options = nil )
        default_tag_options[name.to_sym] = tag_options if tag_options

        define_method(name) do |field, *args|
          return super unless self.class.enabled
          options = args.last.is_a?(Hash) ? args.pop : {}
          options_for_tag = (default_tag_options[name.to_sym] || {}).clone
          # Accept a closure
          options_for_tag = options_for_tag.call(binding, field, options ) if options_for_tag.respond_to? :call
          options = options.reverse_merge( options_for_tag )

          # not (delete || {}) because we support :group => false
          group_options = ( options.has_key?(:group) ? options.delete( :group ) : {} )
          group_options = group_options.dup if group_options.is_a? Hash

          translatable = options.delete(:translatable)
          description = options.delete(:description)

          label_name = options.delete(:label) || @object.class.human_attribute_name(field)
          label = ""
          if options[:label_as_legend]
            # We'll render a legend in spite of a label.
            group_options[:label] = label_name
          else
            label = label(field, *label_name )
          end
          label_at_bottom = options.delete(:label_at_bottom)

          args << options unless args.last.is_a?(Hash)
          
          super_result = super( field, *args )
          
          pre = ""
          post = ""
          
          if( label_at_bottom )
            post += label
          else
            pre += label
          end

          post += group(:type => :translatable) do
            ( translatable === true ? @template.t("ubiquo.translatable_field") : translatable )
          end if translatable
          post += group(:type => :description) do
            description
          end if description

          if group_options
            group(group_options) do
              pre + super_result + post
            end
          else
            pre + super_result + post
          end
        end
      end

      (helpers + ubiquo_helpers).each do |name|
        initialize_method( name )
      end

      # Grouping of fields
      #
      # Options are:
      #   +:type+: the type name of group to render. The default group name is
      #     read from Ubiquo::Config.context(:ubiquo_form_builder).get(:default_group_type)
      #     We get default configuration based on this type.
      #   +:callbacks+: allow to add content before and after with the string
      #     generated with a proc. A hash with :before and :after keys.
      #   +:legend+: to give the text for the legend field.
      # 
      def group(options = {}, &block)
        return yield unless self.class.enabled

        type = options.delete(:type) ||
          Ubiquo::Config.context(:ubiquo_form_builder).get(:default_group_type)

        options = options.reverse_merge( groups_configuration[type] || {})
        options[:class] = [
            options[:class],
            options.delete(:append_class)
        ].delete_if(&:blank?).join(" ")
        tag = options.delete(:content_tag) # Delete it before sending to content_tag
        callbacks = options.delete(:callbacks) || {}
        result = @template.content_tag(tag, options) do
          out = ""
          out += callbacks[:before].call( binding, options ).to_s if callbacks[:before].respond_to?(:call)
          out += @template.capture( &block ).to_s
          out += callbacks[:after].call( binding, options ).to_s if callbacks[:after].respond_to?(:call)
          out
        end
        # Any method here that accepts a block must check before concat
        manage_result( result, block )
      end

      # Block to disable UbiquoFormbBuilder "magic" inside it.
      def custom_block(&block)
        last_status = self.class.enabled
        self.class.enabled = false
        begin
          manage_result( yield, block )
        ensure
          self.class.enabled = last_status
        end
      end

      # Custom group for the submit buttons.
      def submit_group( options = {}, &block )
        options[:type] = :submit_group
        group( options, &block )
      end

      # Button to submit the new form
      def create_button( text = nil, options = {} )
        options = options.reverse_merge( default_tag_options[:create_button] )
        text = text || @template.t(options.delete(:i18n_label_key))
        submit text, options
      end

      # Button to submit on the edit form
      def update_button( text = nil, options = {} )
        options = options.reverse_merge( default_tag_options[:update_button] )
        text = text || @template.t(options.delete(:i18n_label_key))
        submit text, options
      end

      # Shows the back button for a form. Going back to controler index page.
      #
      # +text+ is the text shown in the button.
      # 
      # +options+ available:
      #   +:url+ to go back. It's controller index by default
      #   +:i18n_label_key+ key for the translation unless text is not null
      #   +:js_function+ is the function passed to button_to_function.
      #     "document.location.href=..." by default
      #
      def back_button( text = nil, options = {} )
        # FIXME: this url generation does not support nested controllers
        url = options.delete(:url) ||
          @template.send( "ubiquo_" + (@object.class.to_s.pluralize.underscore) + "_path" )
        options = options.reverse_merge(default_tag_options[:back_button])

        text = text || @template.t(options[:i18n_label_key])
        options.delete(:i18n_label_key)
        js_function = options[:js_function] || "document.location.href='#{url}'"

        @template.button_to_function text, js_function, options
      end

      protected
      # Any method here that accepts a block must check in case it has been called
      # from an erb.
      #
      # In that case we must concat te result to the template, otherways the result
      # will not appear on the response.
      #
      # Notice that block must not have to have an ampersand
      def manage_result result, block
        @template.concat( result ) if @template.send(:block_called_from_erb?, block )
        result
      end

    end
  end
  
end
