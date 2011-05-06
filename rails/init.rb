require 'ubiquo/settings_connectors'
Ubiquo::SettingsConnectors.preload!

Ubiquo::Plugin.register(:ubiquo, directory, config) do |setting|
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
    permit?("settings_management")
  }  
end

Ubiquo::Settings.create_context(:ubiquo_form_builder) do |setting|
  setting.add( :default_tag_options, {
    :text_area => { :class => "visual_editor" },
    :relation_selector => { :append_class => "relation" },
    :date_select => { :group => {:append_class => "datetime"} },
    :datetime_select => { :group => {:append_class => "datetime"} },
    :check_box => {:group => {:class => "form-item-inline"} },
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
  })
  setting.add( :groups_configuration,{
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
    :submit_group => {:content_tag => :div, :class => "form-item-submit"},
  })
  setting.add( :default_group_type, :div )  
end

require 'ubiquo'
config.after_initialize do
  if Ubiquo::Plugin.registered[:ubiquo_i18n]
    Ubiquo::Settings[:settings_connector] = :i18n
    Ubiquo::SettingsConnectors.load! 
  end
end

