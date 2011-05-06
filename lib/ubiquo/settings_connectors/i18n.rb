module Ubiquo
  module SettingsConnectors
    class I18n < Standard

      # Validates the ubiquo_i18n-related dependencies
      # Returning false will halt the connector load
      def self.validate_requirements
        unless Ubiquo::Plugin.registered[:ubiquo_i18n]
          unless Rails.env.test?
            raise ConnectorRequirementError, "You need the ubiquo_i18n plugin to load #{self}"
          else
            return false
          end
        end
        if ::Setting.table_exists?
          setting_columns = ::Setting.columns.map(&:name).map(&:to_sym)
          unless [:locale, :content_id].all?{|field| setting_columns.include? field}
            if Rails.env.test?
              ::ActiveRecord::Base.connection.change_table(:settings, :translatable => true){}
              if ::ActiveRecord::Base.connection.class.included_modules.include?(Ubiquo::Adapters::Mysql)
                # "Supporting" DDL transactions for mysql
                ::ActiveRecord::Base.connection.begin_db_transaction
                ::ActiveRecord::Base.connection.create_savepoint
              end
              ::Setting.reset_column_information
            else
              raise ConnectorRequirementError,
              "The settings table does not have the i18n fields. " +
                "To use this connector, update the table enabling :translatable => true"
            end
          end
        end
      end

      def self.unload!
        ::Setting.instance_variable_set :@translatable, false

      end

      module Settings
        def self.included(klass)
          klass.send(:include, self::InstanceMethods)
          klass.send(:extend, self::ClassMethods)

          I18n.register_uhooks klass, InstanceMethods
          I18n.register_uhooks klass, ClassMethods
        end

        module InstanceMethods
        end

        module ClassMethods

          # Returns the default value for the setting
          def uhook_default_value(name = nil, options = {})
            if translatable?(name)
              locale = options[:locale] rescue nil
              if locale && translation_exists?(name, locale)
                return locale, settings[current_context][name][:options][:default_value][locale]
              elsif translation_exists?(name, default_or_first_locale(name))
                locale = default_or_first_locale(name)
                return locale, settings[current_context][name][:options][:default_value][locale]
              else
                locale = default_or_first_locale(name)
                return locale, settings[current_context][name][:options][:default_value][locale]
              end
            else
              return default_locale, settings[current_context][name][:options][:default_value]
            end
          end

          # Returns the allowed values for the setting
          def uhook_allowed_values(name = nil, options = {})
            return nil if settings[current_context][name][:options][:allowed_values].blank?
            if translatable?(name)
              locale = options[:locale]
              if locale && translation_exists?(name, locale)
                return locale, settings[current_context][name][:options][:allowed_values][locale]
              elsif translation_exists?(name, default_or_first_locale(name))
                locale = default_or_first_locale(name)
                return locale, settings[current_context][name][:options][:allowed_values][locale]
              else
                locale = default_or_first_locale(name)
                return locale, settings[current_context][name][:options][:allowed_values][locale]
              end
            else
              return settings[current_context][name][:options][:allowed_values]
            end
          end            

          # Load all settings from a i18n database backend
          def uhook_load_from_backend!
            regenerate_settings
            return 0 if !overridable?              
            ::Setting.all.map{|s| 
              context(s.context).add(s)                  
            }.length            
          end

          # Add a Setting
          #
          #     Accepts:
          #         - Setting (persistent object on database)
          #         - Hash  = {
          #                        :name => String || Symbol,
          #                        :context => String || Symbol,
          #                        :value => Object
          #                        :options => {}
          #                      }
          #                    - Param1 = name or key of the setting
          #                      Param2 = value of the setting
          #                      Param3 = Hash of options to aply
          #
          #
          def uhook_add(name = nil, default_value = nil, options = {}, &block)
            # override
            if name.is_a?(Setting)              
              return nil if !overridable?
              raise Ubiquo::Settings::InvalidOptionName if options[:is_translatable] && !name.locale 
              value = name.value
              options = {
                :is_a_override => true                
              }
              options.merge!(:locale => name.locale)  if translatable?(name.key)
              set(name.key, value, options) 
            elsif name.is_a?(Hash)
              return nil if !overridable?
              raise Ubiquo::Settings::InvalidOptionName if options[:is_translatable] && !name.locale 
              if options[:is_translatable]                  
                context(name[:context]).set(name[:key], value, :locale => name.locale)
              else
                context(name[:context]).set(name[:key], value) 
              end
              name
            else
              if block_given?
                block_assignment(&block).each do |name, default_value|
                  self.add(name.to_sym, default_value, options)
                end
              else
                raise Ubiquo::Settings::InvalidOptionName if !check_valid_name(name)
                raise Ubiquo::Settings::AlreadyExistingOption if settings[self.current_context].include?(name.to_sym) &&
                                                                !options.delete(:is_a_connector_reload)

                name = name.to_sym
                value = default_value
                options = default_options.merge(options).merge(:default_value => value)
                options.merge!( :original_parameters => {
                    :name => name,
                    :default_value => default_value,
                    :options => options
                  }
                )
                if options[:is_translatable]
                  if default_value.is_a?(Hash)
                    value = default_value
                  else
                    locale = options.delete(:locale) || default_locale  
                    value = { locale.to_sym => value }
                    options.merge!(:default_value => { locale.to_sym => default_value })
                  end
                end
                settings[self.current_context][name] = {
                  :options => options,
                  :value => value                    
                }  
              end
            end    
          end

          # Update a value of a setting
          def uhook_set(name = nil, value = nil, options = {}, &block)
            if block_given?
              block_assignment(&block).each do |name, default_value|
                set(name, default_value, options)
              end
            else
              raise Ubiquo::Settings::InvalidOptionName if !check_valid_name(name)
              raise Ubiquo::Settings::OptionNotFound if !self.option_exists?(name)                

              locale = options[:locale] ? options.delete(:locale).to_sym : nil

              name = name.to_sym
              options = settings[current_context][name][:options].merge(options) 
              if options[:is_translatable]
                value = settings[current_context][name][:value].merge({ locale => value })
              end
              options.merge!(:default_value => value) if !options.delete(:is_a_override)
              options.delete(:inherits)
              settings[current_context][name] = {
                :options => options,
                :value => value       
              }
            end
          end

          # Check if a setting can be translation in a locale
          #
          # locale can be:
          #       - String or symbol: en_US
          #       - Hash: {:locale => :en_US}
          #       - !supplied? : will take the default locale
          #
          def translation_exists?(name, locale = default_locale)
            raise Ubiquo::Settings::OptionNotFound if !self.option_exists?(name) || !translatable?(name)
            settings[current_context][name][:value].is_a?(Hash) && 
            (settings[current_context][name][:value].keys.include?(locale.to_sym) || 
              settings[current_context][name][:value].keys.include?(locale[:locale].to_sym) rescue false
             )
          end

          # Check if a setting can be translated
          def translatable?(name)
            raise Ubiquo::Settings::OptionNotFound if !self.option_exists?(name)
            settings[current_context][name][:options][:is_translatable]
          end

          # Get the value of a setting
          def uhook_get(name, options = {})
            raise Ubiquo::Settings::InvalidOptionName if !check_valid_name(name)
            raise Ubiquo::Settings::OptionNotFound if !self.option_exists?(name)
            name = name.to_sym

            if tree = settings[self.current_context][name][:options][:inherits]
              raise 'unsupported inheritance method' if tree.class != Symbol &&
                                                        (tree.class == String && tree.split('.').length != 2 ||
                                                        tree.class == Hash && tree.keys.length != 1 && !context_exists?(tree.keys.first))

              if tree.class == String
                inherited_context, inherited_key = tree.split('.')
              end
              if tree.class == Hash
                inherited_context, inherited_key = tree.keys.first, tree.values.first
              end
              if tree.class == Symbol
                inherited_context, inherited_key = default_context, tree
              end
              self.context(inherited_context).get(inherited_key)
            else
              if translatable?(name)                  
                if options.is_a?(Hash)
                  locale = options[:locale]
                  locale = default_or_first_locale(name) if !locale && options[:any_value]   
                else
                  locale = options
                end
                locale ||= default_locale
                locale = locale.to_sym
                raise Ubiquo::Settings::ValueNeverSet if (settings[self.current_context][name][:value].nil? || 
                                                        settings[self.current_context][name][:value].nil?) && 
                                                        !is_nullable?(name) ||!translation_exists?(name, locale)
                if overridable?
                  settings[self.current_context][name][:value][locale]
                else
                  settings[self.current_context][name][:options][:default_value][locale]
                end
              else
                raise Ubiquo::Settings::ValueNeverSet if settings[self.current_context][name][:value].nil? && !is_nullable?(name) 
                if overridable?
                  settings[self.current_context][name][:value]
                else
                  settings[self.current_context][name][:options][:default_value]
                end
              end
            end
          end

          def default_or_first_locale name
            if settings[self.current_context][name][:value]
              if settings[self.current_context][name][:value][default_locale]
                default_locale
              else
                settings[self.current_context][name][:value].keys.first
              end
            end              
          end

          def default_locale
            :any
          end

          def uhook_initialize options = {}
            uhook_reinitialize options
            self.settings = { default_context => {} }
          end

          def uhook_reinitialize options = {}
            self.overridable = options[:settings_overridable].present? 
          end

          def uhook_default_options 
            {
              :is_nullable => false,
              :is_editable => false,
              :is_translatable => false,
              :locale => default_locale
            } 
          end            
        end          
      end

      module Setting

        def self.included(klass)
          klass.send :translatable, :value
          klass.send(:include, InstanceMethods)
          klass.send :validate, :check_localization_acceptance
          klass.send(:extend, ClassMethods)
          I18n.register_uhooks klass, InstanceMethods
          I18n.register_uhooks klass, ClassMethods
        end

        module ClassMethods
          def uhook_find_or_build context, key, options = {}
            if Ubiquo::Settings[context].translatable?(key)
              setting = ::Setting.locale(options[:locale].to_s).find(:first,
                                      :conditions => ["context = ? AND key = ? ",
                                                      context.to_s, key.to_s])
            else
              setting = ::Setting.find(:first,
                                        :conditions => ["context = ? AND key = ? ",
                                                      context.to_s, key.to_s])                
            end
            setting ||= uhook_generate_instance(context, key, options)
            setting.locale = options[:locale].to_s
            setting
          end

          def uhook_generate_instance context, key, options = {}
            klass = ::Setting.generate_type(context, key)
            locale, value = Ubiquo::Settings[context].default_value(key, options)
            allowed_values = Ubiquo::Settings[context].allowed_values(key, options)
            options = Ubiquo::Settings[context].options(key, options)
            klass.new(:context => context,
                      :key => key,
                      :locale => locale.to_s,
                      :allowed_values => allowed_values,
                      :value => value,
                      :options => options)
          end            
        end
        module InstanceMethods

          def translatable?
            Ubiquo::Settings[self.context].translatable?(self.key)
          end

          def uhook_generated_from_another_value?
            !self.id &&
              translatable? &&
              !Ubiquo::Settings[self.context].translation_exists?(self.key, self.locale)
          end

          # Check if a not translatable setting override exists and  another with different locale
          # want to be created
          def check_localization_acceptance
            if self.config_exists? &&
                !Ubiquo::Settings[self.context].translatable?(self.key) &&
                (self.translations.present? || 
                ::Setting.find(:first, :conditions => ["context = ? AND key = ? AND locale <> ?",
                                                        context.to_s, key.to_s, locale.to_s]))
              self.errors.add :key, "not translatable setting"
            end
          end

          def uhook_config_value_same?
            !self.id && 
              config_exists? && 
              Ubiquo::Settings[self.context].default_value(self.key, self.locale)[1] == self.value
          end
        end
      end

      module UbiquoSettingsController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          klass.send(:helper, Helper)
          I18n.register_uhooks klass, InstanceMethods
          I18n.register_uhooks klass, ClassMethods

        end

        module Helper
          # Adds a locale filter to the received filter_set
          def uhook_setting_filters filter_set
            filter_set.locale
          end

          # Returns content to show in the sidebar when editing an setting
          def uhook_edit_setting_sidebar setting
            show_translations(setting)
          end

          # Returns content to show in the sidebar when creating an setting
          def uhook_new_setting_sidebar setting
            show_translations(setting)
          end

          # Returns the available actions links for a given setting
          def uhook_setting_index_actions setting
            actions = []
            actions << link_to_function(t('ubiquo.setting.index.save'), "collectAndSendValues('#{setting.context}', '#{setting.key}')")
            if setting.id && !setting.generated_from_another_value?
              actions << link_to(t('ubiquo.setting.index.restore_default'), 
                          ubiquo_setting_path(setting),
                          :confirm => t('ubiquo.setting.index.confirm_restore_default'), :method => :delete)
            end
            actions
          end

          # Returns any necessary extra code to be inserted in the setting form
          def uhook_setting_form form
            (form.hidden_field :content_id) + (hidden_field_tag(:from, params[:from]))
          end            

          def uhook_get_setting(context, setting_key)
            ::Setting.find_or_build(context, setting_key, :locale => current_locale.to_sym)
          end     

          def uhook_print_key_label setting
            result = label_tag(setting.key)
            result += content_tag(:span,"(#{t('ubiquo.setting.index.translatable')})", :class => :translatable) if setting.translatable?
            result += content_tag(:p, "(#{t('ubiquo.setting.index.not_value_for_locale')})") if setting.generated_from_another_value?
            result
          end            
        end

        module ClassMethods

        end          
        module InstanceMethods

          def uhook_index
            Ubiquo::Settings.get_contexts.inject({}) do |result, context|
              settings = Ubiquo::Settings[context].get_editable_settings
              if settings.present?
                result[context] = Ubiquo::Settings[context].get_editable_settings
              end
              result
            end
          end

          def uhook_is_setting_overriden? context, key
            Ubiquo::Settings[context].options_exists?(key) &&
              Ubiquo::Settings[context].translation_exists?(key, current_locale)
          end

          # Returns a hash with extra filters to apply
          def uhook_index_filters
            {:locale => params[:filter_locale]}
          end


          # Performs any required action on setting when in edit
          def uhook_edit_setting setting
            unless setting.in_locale?(current_locale)
              redirect_to(ubiquo_settings_path)
              false
            end
          end

          # For password settings two inputs will be generated. One with the key
          # of the setting and the other with the prefix "confirmation_"
          def confirmation?(key, data)
            !(key !~ /^confirmation_/)  && data.keys.find{|k| k == key.gsub('confirmation_','')}.present?
          end            

          # Creates or updates a new instance of setting.
          def uhook_create_setting
            valids = []
            errors = []
            params[:settings].each do |context, data|
              data.each do |key, value_array|                  
                 unless confirmation?(key, data)
                  setting = ::Setting.find_or_build(context, key, :locale => current_locale)
                  setting.handle_confirmation(data) if setting.respond_to?(:handle_confirmation)
                  setting.value = value_array.first[1]         
                  if setting.config_value_same? || setting.save
                    valids << setting
                  else                    
                    errors << setting
                  end
                end
              end
            end if params[:settings].present?
            {:valids => valids, :errors => errors}
          end

          #destroys an setting instance. returns a boolean that means if the destroy was done.
          def uhook_destroy_setting(setting)
            destroyed = false
            if params[:destroy_content]
              destroyed = setting.destroy_content
            else
              destroyed = setting.destroy
            end
            destroyed
          end
        end
      end

      module Migration

        def self.included(klass)
          klass.send(:extend, ClassMethods)
          I18n.register_uhooks klass, ClassMethods
        end

        module ClassMethods
          def uhook_create_settings_table
            create_table :settings, :translatable => true do |t|
              yield t
            end
          end
        end
      end

      module ActiveRecord
        module Base

          def self.included(klass)
            klass.send(:extend, ClassMethods)
            I18n.register_uhooks klass, ClassMethods
          end

          module ClassMethods
          end
        end
      end

      module UbiquoHelpers
        def self.included(klass)
          klass.append_helper(Helper)
        end

        module Helper
        end
      end

      def self.prepare_mocks
        add_mock_helper_stubs({
          :show_translations => '', 
          :ubiquo_setting_path => '', :current_locale => '',
          :content_tag => '', :hidden_field_tag => '', :locale => Setting,
          :new_ubiquo_setting_path => ''
        })
      end
    end
  end
end
