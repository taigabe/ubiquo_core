require File.dirname(__FILE__) + "/../../../../../../../../test/test_helper.rb"

module Connectors
  class I18nTest < ActiveSupport::TestCase

    if Ubiquo::Plugin.registered[:ubiquo_i18n]

      def setup
      
        @initial_contexts =  Ubiquo::Settings.settings.keys
        @old_configuration = Ubiquo::Settings.settings[Ubiquo::Settings.default_context].clone
        
        UbiquoSetting.destroy_all
        
        if Ubiquo::Settings[:settings_connector] != :i18n
          Ubiquo::Settings[:settings_connector] = :i18n
          Ubiquo::SettingsConnectors.load!
        end

        enable_settings_override
        Ubiquo::Settings.load_from_backend!
        Locale.current = 'test'     
      end
      
      def teardown
        clear_settings
        Locale.current = nil     
        Ubiquo::SettingsConnectors.load!
      end

#      test "i18n is loaded by default when i18n plugin accesible" do
#        assert Ubiquo::SettingsConnectors::I18n, Ubiquo::SettingsConnectors::Base.current_connector
#      end

      test "should load localized values from i18n database backend" do
        
        create_settings_test_case = lambda {
          Ubiquo::Settings.create_context(:foo)
          Ubiquo::Settings.create_context(:foo2)
          create_setting(:context => 'foo', :key => 'first', :value => 'value1')
          create_setting(:context => 'foo', :key => 'second', :value => 'value2')
          create_setting(:context => 'foo', :key => 'third', :value => 'value3')
          create_setting(:context => 'foo2', :key => 'first', :value => 'value4')
        }

        create_overrides_test_case = lambda {
          UbiquoStringSetting.create(:context => :foo, :key => 'first', :value => 'value1_redefinido')
          UbiquoStringSetting.create(:context => :foo, :key => 'first', :value => 'value1_redefinit', :locale => 'ca_ES')

          UbiquoStringSetting.create(:context => :foo, :key => 'second', :value => 'value2_redefinido', :locale => 'es_ES')
          UbiquoStringSetting.create(:context => :foo, :key => 'second', :value => 'value2_redefinit', :locale => 'ca_ES')
          UbiquoStringSetting.create(:context => :foo, :key => 'second', :value => 'value2_overriden', :locale => 'en_UK')

          UbiquoStringSetting.create(:context => :foo2, :key => 'first', :value => 'value4_redefinido')
          UbiquoStringSetting.create(:context => :foo2, :key => 'first', :value => 'value4_redefinit', :locale => 'ca_ES')
        }

        create_settings_test_case.call
        create_overrides_test_case.call

        assert_equal 'value1', Ubiquo::Settings[:foo][:first]
        assert_equal 'value1', Ubiquo::Settings[:foo].get(:first, Ubiquo::Settings.default_locale)
        assert_equal 'value1_redefinido', Ubiquo::Settings[:foo].get(:first, Locale.current)

        clear_settings
        create_settings_test_case.call

        assert_equal 'value1', Ubiquo::Settings[:foo].get(:first)
             
        enable_settings_override
        create_overrides_test_case.call
        assert_equal 'value1_redefinido', Ubiquo::Settings[:foo].get(:first, Locale.current)
       
        clear_settings
        assert !Ubiquo::Settings.context_exists?(:foo)

        create_settings_test_case.call
        enable_settings_override
        create_overrides_test_case.call
        
        
        assert_equal 'value2_redefinido', Ubiquo::Settings[:foo].get(:second, 'es_ES')
        Ubiquo::Settings.reset_overrides
        assert_raise Ubiquo::Settings::ValueNeverSet do
          Ubiquo::Settings[:foo].get(:second, 'es_ES')
        end
        Ubiquo::Settings.load_from_backend!                     
        
        assert_equal Ubiquo::Settings.default_locale, :any
        
        # if translatable, locale by default by default_locale
        assert_equal 'value1', Ubiquo::Settings[:foo][:first]
        assert_equal 'value1', Ubiquo::Settings[:foo].get(:first)
        assert_equal 'value1', Ubiquo::Settings[:foo].get(:first, :locale => nil)
        assert_equal 'value1', Ubiquo::Settings[:foo].get(:first, Ubiquo::Settings.default_locale.to_s)
        assert_equal 'value1', Ubiquo::Settings[:foo].get(:first, Ubiquo::Settings.default_locale.to_sym)
        assert_equal 'value1', Ubiquo::Settings[:foo].get(:first, :locale => :any)
                
        assert_equal 'value2_redefinido', Ubiquo::Settings[:foo].get(:second, 'es_ES')
        assert_equal 'value2_redefinit', Ubiquo::Settings[:foo].get(:second, 'ca_ES')
        assert_equal 'value2_overriden', Ubiquo::Settings[:foo].get(:second, 'en_UK')
        assert_equal 'value4_redefinit', Ubiquo::Settings[:foo2].get(:first, 'ca_ES')
        
        # if no value for default_locale, raise error
        Ubiquo::Settings.settings[:foo][:first][:value].delete(Ubiquo::Settings.default_locale)
        assert_raise Ubiquo::Settings::ValueNeverSet do
          Ubiquo::Settings[:foo].get(:first, Ubiquo::Settings.default_locale)
        end
        assert_raise Ubiquo::Settings::ValueNeverSet do
          Ubiquo::Settings[:foo][:first]
        end        
        # get any translation
        Ubiquo::Settings[:foo].get(:first, :any_value => true)
      end

      test "settings are translatable" do
        assert UbiquoSetting.is_translatable?
      end

      test "create settings migration" do
        ActiveRecord::Migration.expects(:create_table).with(:ubiquo_settings, :translatable => true).once
        ActiveRecord::Migration.uhook_create_ubiquo_settings_table
      end

      test "should accept translation if setting is translatable" do
        Ubiquo::Settings.create_context(:foo_context_1)
        Ubiquo::Settings[:foo_context_1].add(:new_setting, 
                                         'hola',
                                         {
                                           :is_editable => true,
                                           :is_translatable => true,
                                         })
                                       
        s1 = UbiquoStringSetting.new(:context => :foo_context_1, :key => :new_setting, :value => 'hola_redefinido', :locale => "es_ES")
        s1.save
        assert_equal 'hola_redefinido', Ubiquo::Settings[:foo_context_1].get(:new_setting, 'es_ES')        

        s2 = UbiquoSetting.find(s1.id).translate('ca_ES')
        s2.save 
        assert s2.id 
        assert_equal 'hola_redefinido', Ubiquo::Settings[:foo_context_1].get(:new_setting, :es_ES)
        s2.update_attribute :value, 'hola_redefinit'
        assert_equal 'hola_redefinit', Ubiquo::Settings[:foo_context_1].get(:new_setting, :ca_ES)
      end

      test "should overwrite value if setting is not translatable" do
        Ubiquo::Settings.create_context(:foo_context_2)
        Ubiquo::Settings[:foo_context_2].add(:new_setting, 
                                         'hola',
                                         {
                                          :is_editable => true,
                                          :translatable => false,
                                         })
        s1 = UbiquoStringSetting.create(:context => :foo_context_2, :key => :new_setting, :value => 'hola_redefinido', :locale => 'ca_ES')
        assert_equal 'hola_redefinido', Ubiquo::Settings[:foo_context_2].get(:new_setting)
        
        s2 = UbiquoStringSetting.create(:context => :foo_context_2, :key => :new_setting, :value => 'hola_redefinit_no_locale')
        assert s2.errors.present?
        
        s3 = UbiquoStringSetting.create(:context => :foo_context_2, :key => :new_setting, :value => 'hola_redefinit', :locale => 'es_ES')
        assert s3.errors.present?
        
      end

      test 'uhook_edit_ubiquo_setting should redirect if not current locale' do
        Ubiquo::UbiquoSettingsController.any_instance.expects(:current_locale).at_least_once.returns('ca')
        Ubiquo::UbiquoSettingsController.any_instance.expects(:ubiquo_ubiquo_settings_path).at_least_once.returns('')
        Ubiquo::UbiquoSettingsController.any_instance.expects(:redirect_to).at_least_once
        assert_equal false, Ubiquo::UbiquoSettingsController.new.uhook_edit_ubiquo_setting(UbiquoSetting.new(:locale => 'en'))
      end

      # TODO add more tests for the controller methods
    end

    private

    def create_setting options = {}
      default_options = {
        :context => 'foo',
        :key => 'setting_key',
        :value => 'one',
        :options => {
          :is_editable => true,
          :is_translatable => true
        }
      }.merge(options)
      Ubiquo::Settings[default_options[:context].to_sym].add(default_options[:key], 
                                                    default_options[:value],
                                                    default_options[:options])
    end

    def clear_settings
      UbiquoSetting.destroy_all
      Ubiquo::Settings.settings[:ubiquo] = @old_configuration.clone
      Ubiquo::Settings.settings.reject! { |k, v| !@initial_contexts.include?(k)}
    end

    def save_current_settings_connector
      @old_connector = Ubiquo::SettingsConnectors::Base.current_connector
    end

    def reload_old_settings_connector
      @old_connector.load!
    end

  end
end

