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

    assert_raises(Ubiquo::Settings::AlreadyExistingOption) do
      Ubiquo::Settings.add(:new_option)
    end
  end

  #
  #def test_needs_to_add_for_setting_a_value
  #  assert_raises(Ubiquo::Settings::OptionNotFound) do
  #    Ubiquo::Settings.set(:new_option, 1)
  #  end
  #end

  #def test_needs_to_add_for_setting_a_default_value
  #  assert_raises(Ubiquo::Settings::OptionNotFound) do
  #    Ubiquo::Settings.set_default(:new_option, 1)
  #  end
  #end

#def test_usage_of_default_value
#   assert_nothing_raised do
#     Ubiquo::Settings.add(:new_option)
#     Ubiquo::Settings.set_default(:new_option, 1)
#     assert_equal Ubiquo::Settings.get(:new_option), 1
#
#     Ubiquo::Settings.set(:new_option, 2)
#     assert_equal Ubiquo::Settings.get(:new_option), 2
#
#     Ubiquo::Settings.set_default(:new_option, 3)
#     assert_equal Ubiquo::Settings.get(:new_option), 2
#   end
# end

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
    assert_raises(Ubiquo::Settings::ContextNotFound) do
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
    assert_raises(Ubiquo::Settings::ValueNeverSet) do
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

    assert_raises(Ubiquo::Settings::ValueNeverSet) do
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

    assert_raises(Ubiquo::Settings::ValueNeverSet) do
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
    assert Ubiquo::Settings.add(Setting.create(:key => 'one', :value => 'catch22'))

    disable_settings_override
    assert !Ubiquo::Settings.overridable?
    assert_equal 0, Ubiquo::Settings.load_from_backend!
    assert !Ubiquo::Settings.add(Setting.create(:key => 'one', :value => 'catch24'))
  end
  
  def test_load_from_backend!

    disable_settings_override
    Ubiquo::Settings.load_from_backend!

    initial_s1_value = 'catch11'
    initial_s2_value = 'catch12'
    Ubiquo::Settings.add(:one, initial_s1_value, :is_editable => true)
    Ubiquo::Settings.add(:two, initial_s2_value, :is_editable => true)
    s1 = StringSetting.create(:key => 'one', :value => 'catch22')
    s2 = StringSetting.create(:key => 'two', :value => 'catch24')
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
    s1 = Setting.create(:key => 'one', :value => 'catch22')
    s2 = Setting.create(:key => 'two', :value => 'catch24')
    assert_equal initial_s1_value, Ubiquo::Settings.get(:one)
    assert_equal initial_s2_value, Ubiquo::Settings.get(:two)

    enable_settings_override
    Ubiquo::Settings.add(s1)

    assert_equal s1.value, Ubiquo::Settings.get(:one)
    assert_equal initial_s2_value, Ubiquo::Settings.get(:two)
  end

  def test_is_nullable
    Ubiquo::Settings.add(:one)
    assert_raises Ubiquo::Settings::OptionNotFound do
      Ubiquo::Settings.is_nullable?(:i_dont_exists)
    end
    assert !Ubiquo::Settings.is_nullable?(:one)
    Ubiquo::Settings.add(:two, nil, {:is_nullable => false})
    assert !Ubiquo::Settings.is_nullable?(:two)
    Ubiquo::Settings.add(:three, 1, {:is_nullable => false})
    assert !Ubiquo::Settings.is_nullable?(:three)

    Ubiquo::Settings.add(:four, 0, {:is_nullable => true})
    assert Ubiquo::Settings.is_nullable?(:four)
    Ubiquo::Settings.add(:five, nil, {:is_nullable => true})
    assert Ubiquo::Settings.is_nullable?(:five)
  end

  def test_is_editable
    Ubiquo::Settings.add(:one)
    assert_raises Ubiquo::Settings::OptionNotFound do
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
  
    assert_raises Ubiquo::Settings::OptionNotFound do
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

    assert_raises Ubiquo::Settings::InvalidOptionName do
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
  
  def dummy_method(options = {})
    options = {:word => "world"}.merge(options)
    "hello #{options[:word]}"
  end

  protected

  def clear_settings
    Setting.destroy_all
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
