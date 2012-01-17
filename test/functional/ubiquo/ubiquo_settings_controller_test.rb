require File.dirname(__FILE__) + '/../../test_helper'

class Ubiquo::UbiquoSettingsControllerTest < ActionController::TestCase
#  use_ubiquo_fixtures

  def setup
    save_current_settings
    enable_settings_override
    Ubiquo::Settings.create_context(:controller_test) rescue nil
    Ubiquo::Settings.create_context(:controller_test_2) rescue nil
    session[:locale] = "en_US"
#    login_as :admin
  end

  def teardown
    clear_settings
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:contexts)
  end

  def test_should_show_in_index_only_overridable_values
    Ubiquo::Settings[:controller_test].add(:test_index, 'yes please',
      :is_editable => false
    )
    assert_equal 'yes please', Ubiquo::Settings[:controller_test][:test_index]
    get :index

    assert_select '#context_controller_test input[name="test_index"][value="yes please"]', 0
  end

  def test_should_override_a_setting
    Ubiquo::Settings[:controller_test].add(:test_index, 'yes please',
      :is_editable => true
    )
    assert_equal 'yes please', Ubiquo::Settings[:controller_test][:test_index]
    get :index

    assert_select '#context_controller_test input[name="test_index"][value="yes please"]', 1


    assert_difference('UbiquoSetting.count') do
      post_ubiquo_setting :controller_test, :test_index, "no"
    end
    assert_equal 'no', Ubiquo::Settings[:controller_test][:test_index]

    get :index
    assert_select '#context_controller_test input[name="test_index"][value="no"]', 1
  end

  def test_should_not_override_with_invalid_data_nullable
    # nil not allowed
    Ubiquo::Settings[:controller_test].add(:test_index, 'yes please',
      :is_editable => true,
      :is_nullable => false
    )

    assert_no_difference('UbiquoSetting.count') do
      post_ubiquo_setting :controller_test, :test_index, ""
    end

    get :index
    assert_select '#context_controller_test input[name="test_index"][value="yes please"]', 1

    # nil allowed
    Ubiquo::Settings[:controller_test].set(:test_index, 'yes please',
      :is_editable => true,
      :is_nullable => true
    )

    assert_difference('UbiquoSetting.count') do
      post_ubiquo_setting :controller_test, :test_index, "no"
    end

    get :index
    assert_select '#context_controller_test input[name="test_index"][value="yes please"]', 0
    assert_select '#context_controller_test input[name="test_index"]', 1
  end

  def test_should_not_override_with_invalid_data_for_integer
    Ubiquo::Settings[:controller_test].add(:test_index, 1,
      :is_editable => true,
      :is_nullable => false
    )

    # try with string for integer
    assert_no_difference('UbiquoSetting.count') do
      post_ubiquo_setting :controller_test, :test_index, "foo"
    end

    get :index
    assert_select '#context_controller_test input[name="test_index"][value="1"]', 1

    # try with nil for integer
    assert_no_difference('UbiquoSetting.count') do
      post_ubiquo_setting :controller_test, :test_index, ""
    end

    get :index
    assert_select '#context_controller_test input[name="test_index"][value="1"]', 1
  end

  def test_should_not_override_with_invalid_allowed_value
    Ubiquo::Settings[:controller_test].add(:test_index, 1,
      :is_editable => true,
      :allowed_values => [1,2,4,5]
    )

    assert_no_difference('UbiquoSetting.count') do
      post_ubiquo_setting :controller_test, :test_index, "10"
    end

    get :index
    assert_select '#context_controller_test select[name="test_index"] option[value="1"][selected="selected"]', 1

    #try allowed value
    Ubiquo::Settings[:controller_test].set(:test_index, 1,
      :is_editable => true,
      :allowed_values => [1,2,4,5]
    )

    assert_difference('UbiquoSetting.count') do
      post_ubiquo_setting :controller_test, :test_index, "2"
    end

    get :index
    assert_select '#context_controller_test select[name="test_index"] option[value="2"][selected="selected"]', 1
  end

  def test_should_override_multiple_values_ignoring_invalids
    Ubiquo::Settings[:controller_test].add(:test_index_1, 1,
                  :is_editable => true
    )
    Ubiquo::Settings[:controller_test].add(:test_index_2, 2,
                  :is_editable => true
    )
    Ubiquo::Settings[:controller_test_2].add(:test_index_3, 3,
                  :is_editable => true
    )
    Ubiquo::Settings[:controller_test_2].add(:test_index_4, 4,
                  :is_editable => false
    )
    Ubiquo::Settings[:controller_test_2].add(:test_index_5, "foo",
                  :is_editable => true,
                  :is_nullable => false
    )

    assert_difference('UbiquoSetting.count', 3) do
      post_ubiquo_settings :controller_test => {
          :test_index_1 => 11,
          :test_index_2 => 22,
        },
        :controller_test_2 => {
          :test_index_3 => 33,
          :test_index_4 => 44,
          :test_index_5 => "",
        }
    end


    get :index
    assert_select '#context_controller_test input[name="test_index_1"][value="11"]', 1
    assert_select '#context_controller_test input[name="test_index_2"][value="22"]', 1
    assert_select '#context_controller_test_2 input[name="test_index_3"][value="33"]', 1

  end

  # destroy = restore default
  # Destroy Setting and set the default_value for  the setting
  def test_should_destroy_ubiquo_setting
    Ubiquo::Settings[:controller_test].add(:test_index, 'yes please',
      :is_editable => true
    )
    assert_equal 'yes please', Ubiquo::Settings[:controller_test][:test_index]
    setting = UbiquoStringSetting.create :context => :controller_test,
                          :key => :test_index,
                          :value => 'yes please overrided'
    assert_equal 'yes please overrided', Ubiquo::Settings[:controller_test][:test_index]

    get :index
    assert_select '#context_controller_test input[name="test_index"][value="yes please overrided"]', 1

    assert_difference('UbiquoSetting.count', -1) do
      delete :destroy, :id => setting.id
    end


    assert_equal 'yes please', Ubiquo::Settings[:controller_test][:test_index]
    get :index
    assert_select '#context_controller_test input[name="test_index"][value="yes please"]', 1
  end

  def test_should_show_a_checkbox_for_boolean
    Ubiquo::Settings[:controller_test].add(:test_index, true,
      :is_editable => true
    )
    assert_equal true, Ubiquo::Settings[:controller_test][:test_index]
    get :index

    assert_select '#context_controller_test input[name="test_index"][type="checkbox"][value="1"]', 1

    ["0", 0, false, "false", nil, "nil"].each do |value|
      UbiquoBooleanSetting.destroy_all
      assert_difference('UbiquoSetting.count') do
        post_ubiquo_setting :controller_test, :test_index, value
      end

      assert_equal false, Ubiquo::Settings[:controller_test][:test_index]

      get :index
      assert_select '#context_controller_test input[name="test_index"][type="checkbox"]' do |element|
        assert_select "input[checked]", false
      end

      #assert_select '#context_controller_test input[name="test_index"][type="checkbox"]:not([checked="checked"])', 1
    end

    UbiquoBooleanSetting.destroy_all
    enable_settings_override
    ["1", 1, true, "true"].each do |value|
      UbiquoBooleanSetting.destroy_all
      Ubiquo::Settings.settings[:controller_test].delete(:test_index)
      Ubiquo::Settings[:controller_test].add(:test_index, false,
        :is_editable => true
      )
      assert_difference('UbiquoSetting.count') do
        post_ubiquo_setting :controller_test, :test_index, value
      end

      assert_equal true, Ubiquo::Settings[:controller_test][:test_index]

      get :index
      assert_select '#context_controller_test input[name="test_index"][type="checkbox"][value="1"]', 1
    end
  end

  def test_should_show_a_text_area_for_string_text
    Ubiquo::Settings[:controller_test].add(:test_index, 'yes please',
      :is_editable => true,
      :is_text => true
    )
    assert_equal 'yes please', Ubiquo::Settings[:controller_test][:test_index]
    get :index
    assert_select '#context_controller_test textarea[name="test_index"]', 1,
        :html => "yes please"
  end

  def test_should_handle_passwords
    Ubiquo::Settings[:controller_test].add(:test_index, 'gnuine',
      :is_editable => true,
      :is_password => true
    )
    assert_equal 'gnuine', Ubiquo::Settings[:controller_test][:test_index]
    get :index

    assert_select '#context_controller_test input[type="password"][name="test_index"]:not([value="gnuine"])', 1
    assert_select '#context_controller_test input[type="password"][name="confirmation_test_index"]:not([value="gnuine"])', 1

    assert_no_difference(['UbiquoSetting.count', 'UbiquoPasswordSetting.count']) do
      # fail, no confirmation
      post_ubiquo_setting :controller_test, :test_index, "no"
      # fail, confirmation do not match
      post_ubiquo_settings :controller_test => {
        :test_index => 'a',
        :confirmation_test_index => 'b',
      }
      # fail, a confirmation and not the handler key
      assert_raise Ubiquo::Settings::OptionNotFound do
        post_ubiquo_settings :controller_test => {
          :confirmation_test_index => 'b',
        }
      end
    end
    assert_equal 'gnuine', Ubiquo::Settings[:controller_test][:test_index]

    assert_difference(['UbiquoSetting.count', 'UbiquoPasswordSetting.count'], 1) do
      post_ubiquo_settings :controller_test => {
        :test_index => 'a',
        :confirmation_test_index => 'a'
      }
    end
    assert_equal 'a', Ubiquo::Settings[:controller_test][:test_index]
    get :index

    assert_select '#context_controller_test input[type="password"][name="test_index"]:not([value="gnuine"])', 1
    assert_select '#context_controller_test input[type="password"][name="confirmation_test_index"]:not([value="gnuine"])', 1
    assert_select '#context_controller_test input[type="password"][name="test_index"]:not([value="a"])', 1
    assert_select '#context_controller_test input[type="password"][name="confirmation_test_index"]:not([value="a"])', 1

  end

  def test_should_show_index_with_translated_labels
    Ubiquo::Settings.context(:controller_test) do |setting|
      setting.add(:translated_key_setting, 'yes please', :is_editable => true)
      setting.add(:non_translated_key_setting, 'yes please 2', :is_editable => true)
    end

    translated_key = 'This key is translated'
    non_translated_key = 'Non translated key setting'

    Ubiquo::Settings[:supported_locales].each do |locale|
      I18n.backend.store_translations locale,
        {:ubiquo => {:ubiquo_settings => {:controller_test => {:translated_key_setting => {:name => translated_key}}}}}
    end

    get :index
    assert_select "#context_controller_test" do
      assert_select "#controller_test_ubiquo_setting_translated_key_setting"
      assert_select "label", translated_key
      assert_select "#controller_test_ubiquo_setting_non_translated_key_setting"
      assert_select "label", non_translated_key
    end
  end

  def test_should_support_list_of_email
    Ubiquo::Settings.context(:controller_test) do |setting|
      setting.email :list_of_recipients, %w[email1@gnuine.come email2@gnuine.com mail3@gnuine.com],
        :is_editable => true
    end
    assert_difference('UbiquoEmailSetting.count', 1) do
      post_ubiquo_settings :controller_test => {
        :list_of_recipients => 'overrided_email1@gnuine.come,overrided_email2@gnuine.com,overrided_mail3@gnuine.com',
      }
    end

    get :index
    assert_select '#context_controller_test input[name="list_of_recipients"][value="overrided_email1@gnuine.come,overrided_email2@gnuine.com,overrided_mail3@gnuine.com"]', 1
    assert_equal 'overrided_email1@gnuine.come,overrided_email2@gnuine.com,overrided_mail3@gnuine.com', Ubiquo::Settings[:controller_test][:list_of_recipients]
  end

  def test_should_support_list_of_values
    allowed_values = ["element1", "element2", "element3", 2]
    Ubiquo::Settings.context(:controller_test) do |setting|
      setting.list :list_of_things, ["element1", "dungeon", "keeper", 2, 'avoidable'],
        :is_editable => true
      setting.list :list_of_things_with_allowed_values, ["element1", "element2", "element3"],
        :is_editable => true, :allowed_values => allowed_values
    end
    new_values = ['heroes', 'of', 'might' , 'and', 'magic', 2, :a, 3, 1]
    assert_difference('UbiquoListSetting.count', 1) do
      post_ubiquo_settings :controller_test => {
        :list_of_things => new_values
      }
    end

    get :index
    assert_select "#context_controller_test input[name^=\"list_of_things\"][type=\"text\"]", new_values.length
    new_values.each { |v| assert_select "#context_controller_test input[name^=\"list_of_things\"][value=\"#{v}\"]", 1 }
    assert_equal new_values, Ubiquo::Settings[:controller_test][:list_of_things]

    # test allowed_values
    new_values = ['element1', 2]
    assert_difference('UbiquoListSetting.count', 1) do
      post_ubiquo_settings :controller_test => {
        :list_of_things_with_allowed_values => new_values,
      }
    end

    get :index
    assert_select '#context_controller_test select[name^="list_of_things_with_allowed_values"]', 1 do |element|
      assert_select 'option', allowed_values.length
      assert_select 'option[selected="selected"]', new_values.length
      new_values.each { |v| assert_select "option[selected=\"selected\"][value=\"#{v}\"]", 1 }
      assert_equal new_values, Ubiquo::Settings[:controller_test][:list_of_things_with_allowed_values]
    end

    # put a value not allowed
    previous_values = new_values
    updated_at  = UbiquoListSetting.last.updated_at
    new_values = ['banned_element', 1]
    assert_no_difference('UbiquoListSetting.count') do
      post_ubiquo_settings :controller_test => {
        :list_of_things_with_allowed_values => new_values,
      }
      # error and none selected, the field will be market with a error class
      assert_select '#context_controller_test select[name^="list_of_things_with_allowed_values"][class~="error_field"]', 1 do |element|
        assert_select 'option', allowed_values.length
        assert_select 'option[selected="selected"]', 0
        assert_equal previous_values, Ubiquo::Settings[:controller_test][:list_of_things_with_allowed_values]
        assert_equal updated_at, UbiquoListSetting.last.updated_at
      end
    end

    # after error, we again have the form with the persistent values
    get :index
    assert_select '#context_controller_test select[name^="list_of_things_with_allowed_values"]', 1 do |element|
      assert_select 'option', allowed_values.length
      assert_select 'option[selected="selected"]', previous_values.length
      previous_values.each { |v| assert_select "option[selected=\"selected\"][value=\"#{v}\"]", 1 }
      assert_equal previous_values, Ubiquo::Settings[:controller_test][:list_of_things_with_allowed_values]
    end
  end

  private

  def post_ubiquo_settings hash
    post :create, :format => "html", :ubiquo_settings => hash
  end

  def post_ubiquo_setting context, ubiquo_setting, value
    post_ubiquo_settings(
      context => {
        ubiquo_setting => value
      }
    )
  end

  def ubiquo_setting_attributes(options = {})
    default_options = {
    }
    default_options.merge(options)
  end

  def create_ubiquo_setting(subtype, options = {})
    subtype.create(ubiquo_setting_attributes(options))
  end

  def save_current_settings
    UbiquoSetting.destroy_all
    @old_configuration = Ubiquo::Settings.settings.clone
  end

  def clear_settings
    UbiquoSetting.destroy_all
    Ubiquo::Settings.settings = @old_configuration.clone
  end

end
