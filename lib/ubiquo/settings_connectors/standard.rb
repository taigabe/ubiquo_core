module Ubiquo
  module SettingsConnectors
    class Standard < Base

      module Settings

        def self.included(klass)
          klass.send(:include, self::InstanceMethods)
          klass.send(:extend, self::ClassMethods)

          Standard.register_uhooks klass, InstanceMethods
          Standard.register_uhooks klass, ClassMethods
        end

        module InstanceMethods
        end

        module ClassMethods

          # Returns the options for the setting
          def uhook_options(name = nil, options = {})
            return settings[current_context][name][:options].reject{|k,_|
              [:is_editable, :inherits, :type_value,
                :locale, :is_nullable,
                :default_value, :is_translatable,
                :allowed_values, :original_parameters].include?(k)
            }
          end            

          # Returns the default value for the setting
          def uhook_default_value(name = nil, options = {})
            return settings[current_context][name][:options][:default_value]
          end            

          # Returns the possible values for the setting
          def uhook_allowed_values(name = nil, options = {})
            return settings[current_context][name][:options][:allowed_values]
          end              

          def uhook_load_from_backend!
            return 0 if !overridable?
            ::Setting.all.map{|s| add(s)}.length            
          end

          def uhook_add(name = nil, default_value = nil, options = {}, &block)
            if name.is_a?(Setting)
              return nil if !overridable?
              context(name.context).set(name.key, name.value)
              name
            # only used by plugin or application, not for override
            elsif name.is_a?(Hash)
              return nil if !overridable?
              context(name.context).set(name.key, name.value, options)
              name
            else
              if block_given?
                block_assignment(&block).each do |name, default_value|
                  self.add(name.to_sym, default_value)
                end
              else
                raise Ubiquo::Settings::InvalidOptionName if !check_valid_name(name)
                raise Ubiquo::Settings::AlreadyExistingOption if settings[self.current_context].include?(name.to_sym) &&
                                                                !options.delete(:is_a_connector_reload)                  
                name = name.to_sym
                options = default_options.merge(options).merge(:default_value => default_value)
                options.merge!( :original_parameters => {
                    :name => name,
                    :default_value => default_value,
                    :options => options
                  }
                )
                check_type(options[:value_type], default_value) if @loaded && options[:value_type]
                settings[self.current_context][name] = {
                  :options => options,
                  :value => default_value
                }
              end    
            end    
          end

          def uhook_set(name = nil, value = nil, options = {}, &block)
            if block_given?
              block_assignment(&block).each do |name, default_value|
                set(name, default_value)
              end
            else
              raise Ubiquo::Settings::InvalidOptionName if !check_valid_name(name)
              raise Ubiquo::Settings::OptionNotFound if !self.option_exists?(name)
              name = name.to_sym
              check_type(options[:value_type], value) if @loaded && options[:value_type]
              settings[self.current_context][name] = {
                :options => options.merge(:default_value => value),
                :value => value
              }
            end
          end

          def uhook_get(name, options = {})
            raise Ubiquo::Settings::InvalidOptionName if !check_valid_name(name)
            raise Ubiquo::Settings::OptionNotFound.new(name) if !self.option_exists?(name)
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
              raise Ubiquo::Settings::ValueNeverSetted if settings[self.current_context][name][:value].nil? && !is_nullable?(name) 
              if overridable?
                settings[self.current_context][name][:value]
              else
                settings[self.current_context][name][:options][:default_value]
              end
            end
          end

          def uhook_initialize options = {}
#            uhook_reinitialize options
            self.settings = { default_context => {} }
          end

#          def uhook_reinitialize options = {}
#            self.overridable = options[:settings_overridable].present? 
#          end            

          def uhook_default_options 
            {
              :is_nullable => false,
              :is_editable => false,
              :is_translatable => false
            } 
          end            
        end
      end
      module Setting

        def self.included(klass)
          klass.send(:include, InstanceMethods)
          klass.send(:extend, ClassMethods)
          Standard.register_uhooks klass, InstanceMethods
          Standard.register_uhooks klass, ClassMethods
        end

        module ClassMethods
          def uhook_find_or_build context, key
            setting = ::Setting.find(:first,
                                    :conditions => ["context = ? AND key = ? ",
                                                    context, key])
            setting ||= uhook_generate_instance(context, key)
          end

          def uhook_generate_instance context, key, options = {}
            klass = ::Setting.generate_type(context, key)
            value = Ubiquo::Settings[context].default_value(key, options)
            allowed_values = Ubiquo::Settings[context].allowed_values(key, options)
            options = Ubiquo::Settings[context].options(key, options)
            klass.new(:context => context,
                      :key => key,
                      :allowed_values => allowed_values,
                      :value => value,
                      :options => options)
          end
        end

        module InstanceMethods

          def uhook_generated_from_another_value?
            false
          end

          # Returns an identifier value for a given +setting_key+ in this set
          def uhook_setting_identifier_for_key setting_key
            self.select_fittest(setting_key).content_id rescue 0
          end

          # Returns the fittest setting in the requested locale
          def uhook_select_fittest setting, options = {}
          end

          def uhook_config_value_same?
            !self.id && 
              config_exists? && 
              Ubiquo::Settings[self.context].default_value(self.key) == self.value
          end
        end

      end

      module UbiquoSettingsController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          klass.send(:helper, Helper)
          Standard.register_uhooks klass, InstanceMethods
        end

        module Helper
          # Receives a filter_set to add extra filters
          def uhook_setting_filters filter_set
          end

          # Returns content to show in the sidebar when editing a setting
          def uhook_edit_setting_sidebar setting
            ''
          end

          # Returns content to show in the sidebar when creating a setting
          def uhook_new_setting_sidebar setting
            ''
          end

          # Returns the available actions links for a given setting
          def uhook_setting_index_actions setting
            actions = []
            actions << link_to_function(t('ubiquo.setting.index.save'), "collectAndSendValues('#{setting.context}', '#{setting.key}')")
            if setting.id
              actions << link_to(t('ubiquo.setting.index.restore_default'), 
                          ubiquo_setting_path(setting),
                          :confirm => t('ubiquo.setting.index.confirm_restore_default'), :method => :delete)
            end
            actions
          end

          # Returns any necessary extra code to be inserted in the setting form
          def uhook_setting_form form
            ''
          end

          def uhook_setting_value context, key
            Ubiquo::Settings[:context][:key]
          end

          def uhook_get_setting(context, setting_key)
            ::Setting.find_or_build(context,setting_key)
          end

          def uhook_print_key_label setting
            label_tag(translate_key_name(setting.context, setting.key))            
          end            

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
            Ubiquo::Settings[:context].options_exists?(key)
          end

          # Returns a hash with extra filters to apply
          def uhook_index_filters
            {}
          end

          # Initializes a new instance of setting.
          def uhook_new_setting
            ::Setting.new
          end

          # Performs any required action on setting when in edit
          # Edit action will not continue if this hook returns false
          def uhook_edit_setting setting
            true
          end

          # For password settings two inputs will be generated. One with the key
          # of the setting and the other with the prefix "confirmation_"
          def confirmation?(key, data)
            !(key !~ /^confirmation_/)  && data.keys.find{|k| k == key.gsub('confirmation_','')}.present?
          end          

          # Create or update a new instance of setting.
          def uhook_create_setting
            valids = []
            errors = []
            params[:settings].each do |context, data|
              data.each do |key, value_array|
                if confirmation?(key, data)
                  setting = ::Setting.find_or_build(context, key)
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

         #destroys a setting instance. returns a boolean that means if the destroy was done.
          def uhook_destroy_setting(setting)
            setting.destroy 
          end
        end
      end

      module Migration

        def self.included(klass)
          klass.send(:extend, ClassMethods)
          Standard.register_uhooks klass, ClassMethods
        end

        module ClassMethods
          def uhook_create_settings_table
            create_table :settings do |t|
              yield t
            end
          end
        end
      end

      module ActiveRecord
        module Base

          def self.included(klass)
            klass.send(:extend, ClassMethods)
            Standard.register_uhooks klass, ClassMethods
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
      end
    end
  end
end
