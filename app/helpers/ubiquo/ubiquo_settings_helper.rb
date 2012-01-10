module Ubiquo::UbiquoSettingsHelper

  def ubiquo_setting_filters
    uhook_setting_filters
  end

  def ubiquo_setting_list(contexts, form, options = {})
    capture do
      form.group(:type => :tabbed) do
        contexts.map do |context, setting_keys|
          content_tag(:div, :id => "context_#{context}", :class => 'context') do
            form.tab UbiquoSetting.context_translated(context) do
              context_data(context, setting_keys)
            end
          end
        end.join
      end + submit_all_button
    end
  end

  private

  def context_data(context, setting_keys)
    each_setting_key(context, setting_keys) do |ubiquo_setting|
      content_tag(:div, :class => "form-item") do
        setting_info(ubiquo_setting) +
        setting_actions(ubiquo_setting)
      end
    end.join
  end

  def submit_all_button
    content_tag(:div, :class => "form-item-submit") do
      submit_tag(t('ubiquo.ubiquo_setting.index.save_all'),
                  :onclick => javascript_callback,
                  :class => 'save_all')
    end
  end

  def javascript_callback
    "return collectAndSendValues();return false;"
  end

  def setting_info(ubiquo_setting)
    content_tag(:div, :class => "setting-info") do
      print_key_label(ubiquo_setting) +
      render_value(ubiquo_setting)
    end
  end

  def setting_actions(ubiquo_setting)
    content_tag(:div, :class => "setting-actions") do
      content_tag(:ul, :class => "actions") do
        uhook_ubiquo_setting_index_actions(ubiquo_setting).map do |action|
          content_tag(:li, action)
        end
      end
    end
  end

  def each_setting_key(context, setting_keys, &block)
    settings = setting_keys.map do |setting_key|
      get_ubiquo_setting(context, setting_key)
    end
    settings.map {|setting| yield(setting)}
  end

  def render_empty_list_message
    render(:partial => "shared/ubiquo/lists/empty", :locals => {
        :model => UbiquoSetting,
        :name => 'ubiquo_setting',
        :link_to_new => ''
    })
  end

  def render_template_type ubiquo_setting
    type = ubiquo_setting.class.name.gsub('Setting', '').gsub('Ubiquo', '').underscore
    type = UbiquoSetting.name.underscore if type.blank?

    result = render(:partial => "/ubiquo/ubiquo_settings/#{ubiquo_setting.context}/#{ubiquo_setting.key}",
                        :locals => { :ubiquo_setting => ubiquo_setting }) rescue false
    result = render(:partial => "/ubiquo/ubiquo_settings/#{type}",
                        :locals => { :ubiquo_setting => ubiquo_setting }) rescue false if !result
    result = render(:partial => "/ubiquo/ubiquo_settings/ubiquo_setting.html.erb",
                      :locals => { :ubiquo_setting => ubiquo_setting }) if !result
    result
  end

  def render_value ubiquo_setting
    render :partial => 'form', :locals => {:ubiquo_setting => ubiquo_setting}, :class => 'setting'
  end

  def get_ubiquo_setting(context, ubiquo_setting_key)
    add_errors uhook_get_ubiquo_setting(context, ubiquo_setting_key)
  end

  def add_errors ubiquo_setting
    error_dump = self.controller.instance_variable_get(:@result)[:errors] rescue []
    error_object = error_dump.find do |e|
      e.present? &&
      e.context == ubiquo_setting.context &&
        e.key == ubiquo_setting.key
    end
    if error_object.present? && ubiquo_setting.errors.blank?
      ubiquo_setting = error_object
    end
    ubiquo_setting
  end

  def print_key_label ubiquo_setting
    uhook_print_key_label ubiquo_setting
  end

  def setting_dom_id ubiquo_setting
    [ubiquo_setting.context, "ubiquo_setting", ubiquo_setting.key].join('_')
  end

  def error_class ubiquo_setting
    ubiquo_setting.errors.present? ? " error_field" : " "
  end
end
