require 'ubiquo'

require 'ubiquo/settings_connectors'
Ubiquo::SettingsConnectors.preload!

Ubiquo::Plugin.register(:ubiquo) do |setting|
  setting.add :elements_per_page, 10
  setting.add :max_size_for_links_filter, 5
  # :model_groups is a hash :group_name => %w{table names in group}
  setting.add :model_groups, {}
  setting.add(:attachments, {
    :visibility => :public,
    :public_path => "public",
    :private_path => "protected",
    :use_x_send_file => !Rails.env.development?,
  })
  setting.add :required_field_class, 'required_field'
  setting.add :error_field_class, 'error_field'
  setting.add :ubiquo_path, 'ubiquo'
  setting.add :settings_overridable, false
  setting.add :settings_access_control, lambda{
    access_control :DEFAULT => "settings_management"
  }
  setting.add :settings_permit, lambda{
    permit?("ubiquo_settings_management")
  }
end

Ubiquo::Settings.add do |app_config|
  app_config.app_name = "u09"
  app_config.app_title = "U09"
  app_config.app_description = "U09"
  app_config.notifier_email_from = "change@me.com"
  app_config.supported_locales = [:ca, :es, :en ]
  app_config.default_locale = :ca
end

Ubiquo::Settings.add(:edit_on_row_click, true)

Ubiquo::Settings.create_context(:ubiquo_form_builder)
Ubiquo::Settings.context(:ubiquo_form_builder) do |context|
  context.add( :default_tag_options, {
    :text_area => { :class => "visual_editor" },
    :relation_selector => { :append_class => "relation" },
    :check_box => {
      :group => {:class => "form-item"}, :class => "checkbox",
      :html_options_position => 0 # check_box does not has the options in last param but first.
    },
    :create_button => {
      :i18n_label_key => "ubiquo.create",
      :class => "bt-update",
    },
    :update_button => {
      :i18n_label_key => "ubiquo.save",
      :class => "bt-update",
    },
    :back_button => {
      :i18n_label_key => "ubiquo.back_to_list",
    },
    # Some methods have a special signature (datetime_select, etc.) that need
    # a special configuration.
    #
    # This happens when a method can have a hash on more than one parameter or
    # when some fields are not required and the html_options come after.
    #
    # For example datetime_select( obj_name, method, options = {} , html_options = {} )
    # we set:
    #   :base_args => [{},{}],
    #   :html_options_position => 1 # index of the html options
    #
    # The html_options_position is the position of the html_options in the method
    # arguments list.
    #
    :datetime_select => {
      :base_args => [{},{}],
      :html_options_position => 1,
      :group => {:append_class => "datetime"}
    },
    :date_select => {
      :base_args => [{},{}],
      :html_options_position => 1,
      :group => {:append_class => "datetime"}
    },
    :time_select => {
      :base_args => [{},{}],
      :html_options_position => 1,
      :group => {:append_class => "datetime"}
    },
    :collection_select => {
      :base_args => [nil,nil,nil,{},{}],
      :html_options_position => 4,
    },
    :select => {
      :base_args => [nil,{},{}],
      :html_options_position => 2,
    },
    :time_zone_select => {
      :base_args => [nil,{},{}],
      :html_options_position => 2,
    },
    :calendar_date_select => {:group => {:append_class => "datetime"}}
  })
  context.add( :groups_configuration,{
      :div => {:content_tag => :div, :class => "form-item"},
      :fieldset => {
        :content_tag => :fieldset,
        :callbacks => {
          :before =>
            lambda do |context, options|
              # Render the legend tag
              legend_options = options[:legend] || options[:label] || {}
              context.eval("@template").content_tag(:legend, legend_options)
            end
        }
      },
      :tabbed => { :content_tag => :div, :append_class => "form-tab-container" },
      # This group config is used for each tab
      :tab => {:content_tag => :fieldset, :append_class => "form-tab",
        :callbacks => {
          :before =>
            lambda do |context, options|
              # Render the legend tag
              legend_options = options.delete(:legend) || options.delete(:label) || {}
              context.eval("@template").content_tag(:legend, legend_options)
            end
        }
      },
      # Configuration for disabled tab wrapper
      :tabbed_unfolded => { :content_tag => :div, :append_class => "form-tab-container-unfolded" },
      :submit_group => {:content_tag => :div, :class => "form-item-submit"},
      :translatable => {:content_tag => :p, :class => "translation-info"},
      :description  => {:content_tag => :p, :class => "description"},
      :help         => {:partial => "/shared/ubiquo/form_parts/form_help"}
    })
  context.add( :default_group_type, :div )
  # Set to false to unfold the group(:type => :tabbed)
  context.add( :unfold_tabs, false)
end
