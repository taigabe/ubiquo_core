require File.dirname(__FILE__) + "/../../../../../../../../test/test_helper.rb"

module Connectors
  class StandardTest < ActiveSupport::TestCase

      def setup
        save_current_settings_connector 
        Ubiquo::Settings[:settings_connector] = :standard
        clean_translatable_settings
        Ubiquo::SettingsConnectors.load!
        Ubiquo::Settings.regenerate_settings
      end
      
      def teardown
        clear_settings
        reload_old_settings_connector
      end

#      test "i18n is loaded by default when i18n plugin accesible" do
#        assert Ubiquo::SettingsConnectors::Standard, Ubiquo::SettingsConnectors::Base.current_connector
#      end

      test "should load values from database backend" do
        
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
          UbiquoStringSetting.create(:context => :foo, :key => 'second', :value => 'value2_redefinido')
          UbiquoStringSetting.create(:context => :foo2, :key => 'first', :value => 'value3_redefinido')
        }

        Ubiquo::Settings[:ubiquo][:settings_overridable] = true        
        create_settings_test_case.call
        create_overrides_test_case.call
        
        assert_equal 'value1_redefinido', Ubiquo::Settings[:foo][:first]

        Ubiquo::Settings.reset_overrides
        clear_settings
        Ubiquo::Settings[:ubiquo][:settings_overridable] = true        
        create_settings_test_case.call

        assert_equal 'value1', Ubiquo::Settings[:foo][:first]
             
        create_overrides_test_case.call
        assert_equal 'value1_redefinido', Ubiquo::Settings[:foo].get(:first)
       
        clear_settings
        assert !Ubiquo::Settings.context_exists?(:foo)
                
        UbiquoStringSetting.any_instance.stubs(:apply).returns(false)
        create_settings_test_case.call
        
        UbiquoStringSetting.create(:context => :foo, :key => 'first', :value => 'value1_redefinido')
        assert_equal 'value1', Ubiquo::Settings[:foo][:first]
        enable_settings_override
        Ubiquo::Settings.load_from_backend!     
        assert_equal 'value1_redefinido', Ubiquo::Settings[:foo][:first]
      end

      test "create settings migration" do
        ActiveRecord::Migration.expects(:create_table).with(:ubiquo_settings).once
        ActiveRecord::Migration.uhook_create_ubiquo_settings_table
      end

      test "should accept a override if setting is editable" do

        Ubiquo::Settings[:ubiquo][:settings_overridable] = true
        Ubiquo::Settings.create_context(:foo_context_1)
        Ubiquo::Settings[:foo_context_1].add(:new_setting, 
                                         'hola',
                                         {
                                           :is_editable => false,
                                         })
                        
        s1 = UbiquoStringSetting.create(:context => :foo_context_1, :key => :new_setting, :value => 'hola_redefinido')
        assert s1.errors

        Ubiquo::Settings[:foo_context_1].set(:new_setting, 
                                         'hola',
                                         {
                                           :is_editable => true,
                                         })
        s1 = UbiquoStringSetting.create(:context => :foo_context_1, :key => :new_setting, :value => 'hola_redefinido')
        assert_equal 'hola_redefinido', Ubiquo::Settings[:foo_context_1][:new_setting]
      end

    private

    def create_setting options = {}
      default_options = {
        :context => 'foo',
        :key => 'setting_key',
        :value => 'one',
        :options => {
          :is_editable => true,
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
      @initial_contexts =  Ubiquo::Settings.settings.keys
      @old_configuration = Ubiquo::Settings.settings[Ubiquo::Settings.default_context].clone
      
      Ubiquo::SettingsConnectors.load!
    end

    def reload_old_settings_connector
      clear_settings
      @old_connector.load!      
    end

    def clean_translatable_settings
      Ubiquo::Settings.get_contexts.each do |context_key|
        Ubiquo::Settings.settings[context_key].each do |key, value|
          Ubiquo::Settings.settings[context_key].delete(key) if value[:options][:is_translatable] == true
        end
      end
    end
  end
end
