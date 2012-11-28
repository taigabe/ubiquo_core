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
              [:is_editable, :inherits, :value_type, :is_nullable,
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
            regenerate_settings
            ::UbiquoSetting.all.map{|s| add_ubiquo_setting(s)}.compact.length
          end

          def add_ubiquo_setting(s)
            begin
              add(s)
              true
            rescue Exception => e
              Rails.logger.error "Couldn't load the setting #{s.inspect}, please check that the setting already exist in the initializer and the type has not changed"
              nil
            end
          end

          def uhook_add(name = nil, default_value = nil, options = {}, &block)
            if name.is_a?(UbiquoSetting)
              return nil if !overridable?
              value = name.value
              options = {
                :is_a_override => true
              }
              context(name.context).set(name.key, value, options)
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
                check_type(options[:value_type], default_value) if self.loaded && options[:value_type]
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
              options = settings[current_context][name][:options].merge(options)
              check_type(options[:value_type], value) if self.loaded && options[:value_type]
              if !options.delete(:is_a_override)
                options.merge!(:default_value => value)
                options[:original_parameters].merge!({:default_value => value})
              end
              options.delete(:inherits)
              settings[current_context][name] = {
                :options => options,
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
              raise Ubiquo::Settings::ValueNeverSet if settings[self.current_context][name][:value].nil? && !nullable?(name)
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
      module UbiquoSetting

        def self.included(klass)
          klass.send(:include, InstanceMethods)
          klass.send(:extend, ClassMethods)
          Standard.register_uhooks klass, InstanceMethods
          Standard.register_uhooks klass, ClassMethods
        end

        module ClassMethods
          def uhook_find_or_build context, key, options = {}
            setting = ::UbiquoSetting.context(context.to_s).key(key.to_s).first
            setting ||= uhook_generate_instance(context, key)
          end

          def uhook_generate_instance context, key, options = {}
            klass = ::UbiquoSetting.generate_type(context, key)
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
          def uhook_ubiquo_setting_identifier_for_key setting_key
            self.select_fittest(setting_key).content_id rescue 0
          end

          # Returns the fittest ubiquo_setting in the requested locale
          def uhook_select_fittest ubiquo_setting, options = {}
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
          def uhook_ubiquo_setting_filters filter_set
          end

          # Returns content to show in the sidebar when editing a ubiquo_setting
          def uhook_edit_ubiquo_setting_sidebar ubiquo_setting
            ''
          end

          # Returns content to show in the sidebar when creating a ubiquo_setting
          def uhook_new_ubiquo_setting_sidebar ubiquo_setting
            ''
          end

          # Returns the available actions links for a given ubiquo_setting
          def uhook_ubiquo_setting_index_actions ubiquo_setting
            actions = []
            save_text          = t('ubiquo.ubiquo_setting.index.save')
            javascript_handler = "collectAndSendValues('#{ubiquo_setting.context}', '#{ubiquo_setting.key}')"

            actions << link_to_function(save_text, javascript_handler, :class => 'btn-save')

            if ubiquo_setting.id
              restore_text = t('ubiquo.ubiquo_setting.index.restore_default')
              restore_url  = ubiquo_ubiquo_setting_path(ubiquo_setting)
              confirm_text = t('ubiquo.ubiquo_setting.index.confirm_restore_default')

              actions << link_to(restore_text,
                                  restore_url,
                                  :confirm => confirm_text,
                                  :method  => :delete,
                                  :class   => 'btn-restore')
            end
            actions
          end

          # Returns any necessary extra code to be inserted in the ubiquo_setting form
          def uhook_ubiquo_setting_form form
            ''
          end

          def uhook_ubiquo_setting_value context, key
            Ubiquo::Settings[:context][:key]
          end

          def uhook_get_ubiquo_setting(context, setting_key, options = {})
            ::UbiquoSetting.find_or_build(context, setting_key, options)
          end

          def uhook_print_key_label ubiquo_setting
            label_tag(ubiquo_setting.key_translated)
          end

        end
        module InstanceMethods

          def uhook_index
            Ubiquo::Settings.get_contexts.inject(ActiveSupport::OrderedHash.new) do |result, context|
              settings = Ubiquo::Settings[context].get_editable_settings
              if settings.present?
                result[context] = Ubiquo::Settings[context].get_editable_settings
              end
              result
            end
          end

          def uhook_is_setting_overriden? context, key
            Ubiquo::Settings[context].options_exists?(key)
          end

          # Returns a hash with extra filters to apply
          def uhook_index_filters
            {}
          end

          # Initializes a new instance of ubiquo_setting.
          def uhook_new_ubiquo_setting
            ::UbiquoSetting.new
          end

          # Performs any required action on ubiquo_setting when in edit
          # Edit action will not continue if this hook returns false
          def uhook_edit_ubiquo_setting ubiquo_setting
            true
          end

          # For password settings two inputs will be generated. One with the key
          # of the setting and the other with the prefix "confirmation_"
          def confirmation?(key, data)
            !(key !~ /^confirmation_/)  && data.keys.find{|k| k == key.gsub('confirmation_','')}.present?
          end

          # Create or update a new instance of ubiquo_setting.
          def uhook_create_ubiquo_setting options_for_find_or_build = {}
            {}.tap do |result|
              result[:valids] = []
              result[:errors] = []
              params[:ubiquo_settings].each do |context, data|
                data.each do |key, value_array|
                  unless confirmation?(key, data)
                    ubiquo_setting = ::UbiquoSetting.find_or_build(context, key, options_for_find_or_build)
                    ubiquo_setting.handle_confirmation(data) if ubiquo_setting.respond_to?(:handle_confirmation)
                    ubiquo_setting.value = value_array
                    if ubiquo_setting.config_value_same? || ubiquo_setting.save
                      result[:valids] << ubiquo_setting
                    else
                      result[:errors] << ubiquo_setting
                    end
                  end
                end
              end
            end
          end

          #destroys a ubiquo_setting instance. returns a boolean that means if the destroy was done.
          def uhook_destroy_ubiquo_setting(ubiquo_setting)
            ubiquo_setting.destroy
          end
        end
      end

      module Migration

        def self.included(klass)
          klass.send(:extend, ClassMethods)
          Standard.register_uhooks klass, ClassMethods
        end

        module ClassMethods
          def uhook_create_ubiquo_settings_table
            create_table :ubiquo_settings do |t|
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
