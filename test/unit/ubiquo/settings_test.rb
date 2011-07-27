require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::SettingsTest < ActiveSupport::TestCase
  include Ubiquo::Extensions::ConfigCaller

  def setup
    save_current_settings
  end
  
  def teardown
    clear_settings
  end

  def test_add_new_option
    assert_nothing_raised do
      Ubiquo::Settings.add(:new_option)
      Ubiquo::Settings.set(:new_option, 1)
      assert_equal Ubiquo::Settings.get(:new_option), 1
    end
  end

  def test_add_new_option_only_once
    assert_nothing_raised do
      Ubiquo::Settings.add(:new_option)
    end

    assert_raise(Ubiquo::Settings::AlreadyExistingOption) do
      Ubiquo::Settings.add(:new_option)
    end
  end
  
  def test_needs_to_add_for_setting_a_value
    assert_raise(Ubiquo::Settings::OptionNotFound) do
      Ubiquo::Settings.set(:new_option, 1)
    end
  end

  def test_massive_add
    assert_nothing_raised do
      Ubiquo::Settings.add do |config|
        config.a = 1
        config.b = 2
        config.c = 3
      end

      assert_equal Ubiquo::Settings.get(:a), 1
      assert_equal Ubiquo::Settings.get(:b), 2
      assert_equal Ubiquo::Settings.get(:c), 3
    end
  end

  def test_massive_default_options
    Ubiquo::Settings.add(:a)
    Ubiquo::Settings.add(:b)
    Ubiquo::Settings.add(:c)
    assert_nothing_raised do
      Ubiquo::Settings.set_default do |config|
        config.a = 1
        config.b = 2
        config.c = 3
      end

      assert_equal Ubiquo::Settings.get(:a), 1
      assert_equal Ubiquo::Settings.get(:b), 2
      assert_equal Ubiquo::Settings.get(:c), 3
    end
  end

  def test_massive_default_options
    Ubiquo::Settings.add(:a)
    Ubiquo::Settings.add(:b)
    Ubiquo::Settings.add(:c)
    assert_nothing_raised do
      Ubiquo::Settings.set do |config|
        config.a = 1
        config.b = 2
        config.c = 3
      end

      assert_equal Ubiquo::Settings.get(:a), 1
      assert_equal Ubiquo::Settings.get(:b), 2
      assert_equal Ubiquo::Settings.get(:c), 3
    end
  end
  
  def test_context_creation_required_to_use_it
    assert !Ubiquo::Settings.context_exists?(:new_context)
    assert_raise(Ubiquo::Settings::ContextNotFound) do
       Ubiquo::Settings.context(:new_context).add(:a)
    end
  end
  
  def test_block_context_option
    Ubiquo::Settings.create_context(:new_context)
    Ubiquo::Settings.add(:a, 1) # Global option
    Ubiquo::Settings.context(:new_context) do |ubiquo_config|
      ubiquo_config.add(:a, 2)
    end
    
    Ubiquo::Settings.context(:new_context) do |ubiquo_config|
      assert_equal ubiquo_config.get(:a), 2
    end
    assert_equal Ubiquo::Settings.get(:a), 1
  end
  
  def test_inline_context_option
    Ubiquo::Settings.create_context(:foo_context)
    Ubiquo::Settings.add(:a, 1) # Global option
    Ubiquo::Settings.context(:foo_context).add(:a, 2)
    
    assert_equal 2, Ubiquo::Settings.context(:foo_context){ |c| c.get(:a)}
    assert_equal 1, Ubiquo::Settings.get(:a)
  end
  
  def test_caller
    Ubiquo::Settings.add(:a, lambda{"return this"})
    assert_equal "return this", self.ubiquo_config_call(:a)
  end
  
  def test_caller_in_current_binding
    Ubiquo::Settings.add(:a, lambda{dummy_method})
    assert_equal dummy_method,  self.ubiquo_config_call(:a)
  end
  
  def test_caller_with_parameters
    Ubiquo::Settings.add(:a, lambda{|options| dummy_method(options)})
    assert_equal dummy_method({:word => "man"}),  self.ubiquo_config_call(:a, {:word => "man"})
  end
  
  def test_caller_with_parameters_from_external_context
    ExternalContext.test
    assert_equal dummy_method({:word => "man"}),  self.ubiquo_config_call(:a, {:word => "man"})
  end
  
  def test_caller_with_symbol
    Ubiquo::Settings.add(:a, :dummy_method)
    assert_equal dummy_method, self.ubiquo_config_call(:a)
  end
  
  def test_caller_with_symbol_and_parameters
    Ubiquo::Settings.add(:a, :dummy_method)
    assert_equal dummy_method({:word => "man"}), self.ubiquo_config_call(:a, {:word => "man"})
  end
  
  def test_caller_with_context
    Ubiquo::Settings.create_context(:new_context)
    Ubiquo::Settings.context(:new_context).add(:a, lambda{|options|
        dummy_method(options)
      })
  
    assert_equal dummy_method({:word => "man"}),  self.ubiquo_config_call(:a, {:context => :new_context, :word => "man"})
  end
  
  def test_inheritance
    Ubiquo::Settings.add(:a, "hello")
    Ubiquo::Settings.add(:b)
    assert_raise(Ubiquo::Settings::ValueNeverSet) do
      Ubiquo::Settings.get(:b)
    end
    Ubiquo::Settings.add_inheritance(:b, :a)

    assert_nothing_raised do
      assert_equal "hello", Ubiquo::Settings.get(:b)
    end
    
    Ubiquo::Settings.set(:a, "Bye")
    assert_nothing_raised do
      assert_equal "Bye", Ubiquo::Settings.get(:b)
    end
    
    Ubiquo::Settings.set(:b, "Hello again")
    assert_nothing_raised do
      assert_equal "Hello again", Ubiquo::Settings.get(:b)
    end
  end
  
  def test_inheritance_in_different_context
    Ubiquo::Settings.create_context(:new_context_1)
    Ubiquo::Settings.create_context(:new_context_2)
    
    Ubiquo::Settings.context(:new_context_1).add(:a, "hello")
    Ubiquo::Settings.context(:new_context_2).add(:b)    

    assert_raise(Ubiquo::Settings::ValueNeverSet) do
      Ubiquo::Settings.context(:new_context_2).get(:b)
    end
    Ubiquo::Settings.context(:new_context_2).add_inheritance(:b, :new_context_1 =>:a)
    assert_nothing_raised do
      assert_equal "hello", Ubiquo::Settings.context(:new_context_2).get(:b)
    end
  end
  
  def test_inheritance_in_context_to_base
    Ubiquo::Settings.create_context(:foo_context)
    
    Ubiquo::Settings.add(:a, "hello")
    Ubiquo::Settings.context(:foo_context).add(:b)    

    assert_raise(Ubiquo::Settings::ValueNeverSet) do
      Ubiquo::Settings.context(:foo_context).get(:b)
    end
    Ubiquo::Settings.context(:foo_context).add_inheritance(:b, :a)
    assert_nothing_raised do
      assert_equal "hello", Ubiquo::Settings.context(:foo_context).get(:b)
    end
  end
 
  def test_overriding_enabling

    disable_settings_override
    Ubiquo::Settings.load_from_backend!
 
    initial_s1_value = 'catch11'
    initial_s2_value = 'catch12'
    Ubiquo::Settings.add(:one, initial_s1_value)
    Ubiquo::Settings.add(:two, initial_s2_value)
    assert !Ubiquo::Settings.overridable?

    enable_settings_override
    assert Ubiquo::Settings.overridable?
    assert_not_nil Ubiquo::Settings.load_from_backend!
    assert Ubiquo::Settings.add(UbiquoSetting.create(:key => 'one', :value => 'catch22'))

    disable_settings_override
    assert !Ubiquo::Settings.overridable?
    assert_equal 0, Ubiquo::Settings.load_from_backend!
    assert !Ubiquo::Settings.add(UbiquoSetting.create(:key => 'one', :value => 'catch24'))
  end
  
  def test_load_from_backend!

    disable_settings_override
    Ubiquo::Settings.load_from_backend!

    initial_s1_value = 'catch11'
    initial_s2_value = 'catch12'
    Ubiquo::Settings.add(:one, initial_s1_value, :is_editable => true)
    Ubiquo::Settings.add(:two, initial_s2_value, :is_editable => true)
    s1 = UbiquoStringSetting.create(:key => 'one', :value => 'catch22')
    s2 = UbiquoStringSetting.create(:key => 'two', :value => 'catch24')
    assert_equal initial_s1_value, Ubiquo::Settings.get(:one)
    assert_equal initial_s2_value, Ubiquo::Settings.get(:two)

    enable_settings_override
    Ubiquo::Settings.load_from_backend!
    assert_equal s1.value, Ubiquo::Settings.get(:one)
    assert_equal s2.value, Ubiquo::Settings.get(:two)
  end

  def test_add_setting
    disable_settings_override    
    initial_s1_value = 'catch11'
    initial_s2_value = 'catch12'
    Ubiquo::Settings.add(:one, initial_s1_value, :is_editable => true)
    Ubiquo::Settings.add(:two, initial_s2_value, :is_editable => true)
    s1 = UbiquoSetting.create(:key => 'one', :value => 'catch22')
    s2 = UbiquoSetting.create(:key => 'two', :value => 'catch24')
    assert_equal initial_s1_value, Ubiquo::Settings.get(:one)
    assert_equal initial_s2_value, Ubiquo::Settings.get(:two)

    enable_settings_override
    Ubiquo::Settings.add(s1)

    assert_equal s1.value, Ubiquo::Settings.get(:one)
    assert_equal initial_s2_value, Ubiquo::Settings.get(:two)
  end

  def test_nullable?
    Ubiquo::Settings.add(:one)
    assert_raise Ubiquo::Settings::OptionNotFound do
      Ubiquo::Settings.nullable?(:i_dont_exists)
    end
    assert !Ubiquo::Settings.nullable?(:one)
    Ubiquo::Settings.add(:two, nil, {:is_nullable => false})
    assert !Ubiquo::Settings.nullable?(:two)
    Ubiquo::Settings.add(:three, 1, {:is_nullable => false})
    assert !Ubiquo::Settings.nullable?(:three)

    Ubiquo::Settings.add(:four, 0, {:is_nullable => true})
    assert Ubiquo::Settings.nullable?(:four)
    Ubiquo::Settings.add(:five, nil, {:is_nullable => true})
    assert Ubiquo::Settings.nullable?(:five)
  end

  def test_editable
    Ubiquo::Settings.add(:one)
    assert_raise Ubiquo::Settings::OptionNotFound do
      Ubiquo::Settings.editable?(:i_dont_exists)
    end
    assert !Ubiquo::Settings.editable?(:one)
    Ubiquo::Settings.add(:two, nil, {:is_editable => false})
    assert !Ubiquo::Settings.editable?(:two)
    Ubiquo::Settings.add(:three, 1, {:is_editable => false})
    assert !Ubiquo::Settings.editable?(:three)

    Ubiquo::Settings.add(:four, 0, {:is_editable => true})
    assert Ubiquo::Settings.editable?(:four)
    Ubiquo::Settings.add(:five, nil, {:is_editable => true})
    assert Ubiquo::Settings.editable?(:five)
  end  

  def test_square_brakets
    Ubiquo::Settings.create_context :foo_context
    Ubiquo::Settings.context(:foo_context).add(:one, 22)
    assert_equal 22, Ubiquo::Settings.context(:foo_context)[:one]

    Ubiquo::Settings.add(:two, 23)
    assert_equal 23, Ubiquo::Settings[:two]

    assert_equal 22, Ubiquo::Settings[:foo_context][:one]
    assert_equal Ubiquo::Settings.context(:foo_context)[:one], Ubiquo::Settings[:foo_context][:one]
  
    assert_raise Ubiquo::Settings::OptionNotFound do
      Ubiquo::Settings[:i_dont_exist]
    end
  end
  
  def test_square_brakets_assignment
    Ubiquo::Settings.create_context :foo_context

    Ubiquo::Settings.context(:foo_context).add(:one, 22)

    Ubiquo::Settings.context(:foo_context)[:one] = 44 
    assert_equal 44, Ubiquo::Settings.context(:foo_context)[:one]

    Ubiquo::Settings.add(:two, 23)
    Ubiquo::Settings[:two] = 46 
    Ubiquo::Settings.context(Ubiquo::Settings.default_context)[:two] = 46 

    assert_equal 46, Ubiquo::Settings[:two]

    assert_raise Ubiquo::Settings::InvalidOptionName do
      Ubiquo::Settings[:i_dont_exist] = 2
    end

  end

  def test_editable_settings
    Ubiquo::Settings.create_context :foo_context

    Ubiquo::Settings.context(:foo_context).add(:one, 1)
    Ubiquo::Settings.context(:foo_context).add(:two, 2, :is_editable => false)
    Ubiquo::Settings.context(:foo_context).add(:three, 3, :is_editable => true)
    Ubiquo::Settings.context(:foo_context).add(:four, 4, :is_editable => true)

    assert_equal [:four, :three], Ubiquo::Settings[:foo_context].get_editable_settings
  
    Ubiquo::Settings.add(:five,   5)
    Ubiquo::Settings.add(:six,    6, :is_editable => false)
    Ubiquo::Settings.add(:seven,  7, :is_editable => true)
    Ubiquo::Settings.add(:eight,  8, :is_editable => true)

    assert_equal [:eight, :seven], Ubiquo::Settings.get_editable_settings
    assert_equal [:eight, :seven], Ubiquo::Settings.context(Ubiquo::Settings.default_context).get_editable_settings

  end

  def test_type_restricted_settings
    Ubiquo::Settings.create_context(:foo_context) do |setting|
      setting.integer :one, 1
      setting.string :two, "1"
      setting.symbol :three, :a
      setting.email :four, 'a@b.com'
      setting.password :five, 'gnuine'
    end

    Ubiquo::Settings.context(:foo_context) do |setting|
      assert_equal 1, setting[:one]
      assert_equal "1", setting[:two]
      assert_equal :a, setting[:three]
      assert_equal 'a@b.com', setting[:four]
      assert_equal 'gnuine', setting[:five]
    end

    assert_equal UbiquoIntegerSetting, Ubiquo::Settings.settings[:foo_context][:one][:options][:value_type]
    assert_equal UbiquoStringSetting, Ubiquo::Settings.settings[:foo_context][:two][:options][:value_type]
    assert_equal UbiquoSymbolSetting, Ubiquo::Settings.settings[:foo_context][:three][:options][:value_type]
    assert_equal UbiquoEmailSetting, Ubiquo::Settings.settings[:foo_context][:four][:options][:value_type]
    assert_equal UbiquoPasswordSetting, Ubiquo::Settings.settings[:foo_context][:five][:options][:value_type]
    
    Ubiquo::Settings.context(:foo_context) do |setting|
      assert_raise Ubiquo::Settings::InvalidUbiquoIntegerSettingValue do
        setting[:one] = "1"
      end
      assert_raise Ubiquo::Settings::InvalidUbiquoStringSettingValue do
        setting[:two] = 1
      end
      assert_raise Ubiquo::Settings::InvalidUbiquoSymbolSettingValue do
        setting[:three] = "1"
      end
      assert_raise Ubiquo::Settings::InvalidUbiquoEmailSettingValue do
        setting[:four] = "withoutEmailFormat"
      end
      assert_raise Ubiquo::Settings::InvalidUbiquoPasswordSettingValue do
        setting[:five] = 1
      end
    end

    Ubiquo::Settings.context(:foo_context) do |setting|
      assert_raise Ubiquo::Settings::InvalidUbiquoIntegerSettingValue do
        setting.integer :one_bis, "1"
      end
      assert_raise Ubiquo::Settings::InvalidUbiquoStringSettingValue do
        setting.string :two_bis, 1
      end
      assert_raise Ubiquo::Settings::InvalidUbiquoSymbolSettingValue do
        setting.symbol :three_bis, 1
      end
      assert_raise Ubiquo::Settings::InvalidUbiquoEmailSettingValue do
        setting.email :four_bis, "withoutEmailFormat"
      end
      assert_raise Ubiquo::Settings::InvalidUbiquoPasswordSettingValue do
        setting.password :five_bis, 1
      end
    end
  end

  def test_overridable?

    default_overridable_key = Ubiquo::Settings.default_overridable_key
    default_context = Ubiquo::Settings.default_context
    assert_equal false, Ubiquo::Settings[default_overridable_key]
    assert_equal Ubiquo::Settings.settings[default_context][default_overridable_key][:value], 
                Ubiquo::Settings[default_overridable_key]    
    assert_equal Ubiquo::Settings[default_overridable_key], Ubiquo::Settings[default_context][default_overridable_key]
    assert !Ubiquo::Settings.overridable?

    Ubiquo::Settings[default_overridable_key] = true

    assert Ubiquo::Settings.overridable?
    assert Ubiquo::Settings.settings[default_context][default_overridable_key][:value]
  end

  def test_options
    default_context = Ubiquo::Settings.default_context

    # do not show is_editable
    Ubiquo::Settings.string :a, 'abc', :is_editable => true,
      :invented_option => 2
    assert !Ubiquo::Settings.options(:a).include?(:is_editable)
    assert Ubiquo::Settings.options(:a).include?(:invented_option)
    assert({ :invented_option => 2 }, Ubiquo::Settings.options(:a))
    assert_equal 2, Ubiquo::Settings.options(:a)[:invented_option]
    assert Ubiquo::Settings.settings[default_context][:a][:options].include?(:is_editable)

    # do not show inherits
    Ubiquo::Settings.string :b
    Ubiquo::Settings.add_inheritance(:b, :a)
    assert !Ubiquo::Settings.options(:a).include?(:inherits)
    assert Ubiquo::Settings.settings[default_context][:b][:options].include?(:inherits)

    # do not show value_type
    Ubiquo::Settings.string(:c, 'bla')
    assert !Ubiquo::Settings.options(:c).include?(:value_type)
    assert Ubiquo::Settings.settings[default_context][:c][:options].include?(:value_type)
    Ubiquo::Settings.add(:d, 'cla')
    assert !Ubiquo::Settings.options(:d).include?(:value_type)
    assert !Ubiquo::Settings.settings[default_context][:d][:options].include?(:value_type)

    # do not show is_translatable
    Ubiquo::Settings.string(:e, 
                            { 'en_US' => 'dungeon',
                              'es_ES' => 'mazmorra',
                              'ca_ES' => 'masmorra',
                            },
                            :is_translatable => true
                            )
    assert !Ubiquo::Settings.options(:a).include?(:is_translatable)

    # do not show default_value
    Ubiquo::Settings.add(:f, true)
    Ubiquo::Settings.add(:g)
    assert !Ubiquo::Settings.options(:f).include?(:default_value)
    assert Ubiquo::Settings.settings[default_context][:f][:options][:default_value]
    assert !Ubiquo::Settings.options(:g).include?(:default_value)
    assert_equal nil, Ubiquo::Settings.settings[default_context][:g][:options][:default_value]

    # do not show allowed_values
    Ubiquo::Settings.add(:h, 1, :allowed_values => [1,2,3,4,5])
    assert !Ubiquo::Settings.options(:h).include?(:allowed_values)
    assert_equal [1,2,3,4,5], Ubiquo::Settings.settings[default_context][:h][:options][:allowed_values]

    # do not show original parameters
    Ubiquo::Settings.add(:i, 1, :is_editable => true, :allowed_values => [6,7,8])
    assert !Ubiquo::Settings.options(:i).include?(:allowed_values)
    assert_equal [6,7,8], Ubiquo::Settings.settings[default_context][:i][:options][:original_parameters][:options][:allowed_values]

  end

  def should_return_allowed_values
    Ubiquo::Settings.add(:a, 1)
    assert !Ubiquo::Settings.allowed_values(:a)

    Ubiquo::Settings.add(:b, 1, :allowed_values => [1,2,3,4,5])
    assert_equal [1,2,3,4,5], Ubiquo::Settings.allowed_values(:b)
    
    Ubiquo::Settings.create_context(:another).add(:c, 1, :allowed_values => [6,7,8,9,10])
    assert_equal [6,7,8,9,10], Ubiquo::Settings.allowed_values(:c)
    assert_equal [6,7,8,9,10], Ubiquo::Settings[:another].allowed_values(:c)
  end

  def should_return_default_value
    Ubiquo::Settings.add(:a)
    assert !Ubiquo::Settings.default_value(:a)

    Ubiquo::Settings.add(:b, 1)
    assert_equal 1, Ubiquo::Settings.allowed_values(:b)

    Ubiquo::Settings.create_context(:another).add(:c, 2)
    assert_equal 2, Ubiquo::Settings.default_value(:c)
    assert_equal 2, Ubiquo::Settings[:another].default_value(:c)
    assert_equal 2, Ubiquo::Settings[:another][:c][:options][:default_value]
  end

  def test_get_editable_settings
    Ubiquo::Settings.create_context(:another) do |setting|
      setting.integer :a, 1
      setting.integer :c, 2, :is_editable => true
      setting.integer :b, 3, :is_editable => true
      setting.integer :d, 4, :is_editable => true
      setting.integer :e, 5, :is_editable => false
    end
    
    assert_equal [:b, :c, :d], Ubiquo::Settings[:another].get_editable_settings
    assert_equal [3,2,4], Ubiquo::Settings[:another].get_editable_settings.map{|v| Ubiquo::Settings[:another][v] }
  end

  def test_get_contexts
    Ubiquo::Settings.create_context(:foo_first)
    Ubiquo::Settings.create_context(:foo_third)
    Ubiquo::Settings.create_context(:foo_second)    

    index = Ubiquo::Settings.get_contexts.index(:foo_first)
    assert_equal [:foo_first, :foo_second, :foo_third], Ubiquo::Settings.get_contexts[index..(index+2)]
  end
  
  def dummy_method(options = {})
    options = {:word => "world"}.merge(options)
    "hello #{options[:word]}"
  end

  protected

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

class ExternalContext
  def self.test
    Ubiquo::Settings.add(:a, lambda{|options| self.dummy_method(options)})
  end
end
