require File.dirname(__FILE__) + '/../test_helper'

class UbiquoSettingTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  
  def setup
    save_current_settings
  end
  
  def teardown
    clear_settings
  end

  def test_setting_subtypes
    {UbiquoSymbolSetting => :s,
      UbiquoStringSetting => "s",
      UbiquoIntegerSetting => 1,
      UbiquoBooleanSetting => true,
      UbiquoEmailSetting => "a@b.com",
      UbiquoListSetting => [1,'a',:s]}.each do |subtype, value|

      # ubiquo:config.add .....
      key = "#{subtype}_key"
      Ubiquo::Settings.add(key.to_sym, nil, {:is_nullable => true,
                                            :is_editable => true})

      assert_difference ["#{subtype.name}.count", 'UbiquoSetting.count'] do
        ubiquo_setting = create_ubiquo_setting(subtype, :key => key, :value => value)
        assert !ubiquo_setting.new_record?, "#{ubiquo_setting.errors.full_messages.to_sentence}"
        assert ubiquo_setting.type == subtype.name
        assert ubiquo_setting.class == subtype
      end
    end
  end

  def test_should_not_create_values_for_not_existent_settings
     assert_no_difference ['UbiquoSetting.count', 'UbiquoStringSetting.count'] do
     ubiquo_setting = create_ubiquo_setting(UbiquoStringSetting, :key => "foooo")
     assert ubiquo_setting.errors.on(:key)
   end
   
  end

  def test_requires_existent_context
    assert_no_difference ['UbiquoSetting.count', 'UbiquoStringSetting.count'] do
      ubiquo_setting = create_ubiquo_setting(UbiquoStringSetting, :context => "non-existant")
      assert ubiquo_setting.errors.on(:context)
    end
  end

  def test_should_require_key
    assert_no_difference ['UbiquoSetting.count', 'UbiquoStringSetting.count'] do
      ubiquo_setting = create_ubiquo_setting(UbiquoStringSetting, :key => "")
      assert ubiquo_setting.errors.on(:key)
    end
  end

  def test_should_require_value_if_not_nullable
    key = "not_nullable_setting"
    Ubiquo::Settings.add(key, "Hello!")
    assert_no_difference ['UbiquoSetting.count', 'UbiquoStringSetting.count'] do
      ubiquo_setting = create_ubiquo_setting(UbiquoStringSetting, :key => key)
      assert ubiquo_setting.errors.on(:value)
    end

    key = "not_nullable_setting_clone"
    Ubiquo::Settings.add(key, "Hello!", :is_nullable => false)
    assert_no_difference ['UbiquoSetting.count', 'UbiquoStringSetting.count'] do
      ubiquo_setting = ubiquo_create_setting(UbiquoStringSetting, :key => key)
      assert ubiquo_setting.errors.on(:value)
    end

    key = "nullable_setting"
    Ubiquo::Settings.add(key, "Hello!", :is_nullable => true, :is_editable => true)
    assert_difference ['UbiquoSetting.count', 'UbiquoStringSetting.count'] do
      ubiquo_setting = create_ubiquo_setting(UbiquoStringSetting, :key => key)
      assert !ubiquo_setting.new_record?, "#{ubiquo_setting.errors.full_messages.to_sentence}"
    end
  end

  protected

  def create_ubiquo_setting(subtype, options = {})
    default_options = {
    }
    subtype.create(options.merge(default_options))
  end
  
  def clear_settings
    UbiquoSetting.destroy_all
    Ubiquo::Settings.settings[:ubiquo] = @old_configuration.clone
    Ubiquo::Settings.settings.reject! { |k, v| !@initial_contexts.include?(k)}      
  end

  def save_current_settings  
    @initial_contexts =  Ubiquo::Settings.settings.keys
    @old_configuration = Ubiquo::Settings.settings[Ubiquo::Settings.default_context].clone    
  end

end
