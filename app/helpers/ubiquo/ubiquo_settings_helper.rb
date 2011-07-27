module Ubiquo::UbiquoSettingsHelper

  def ubiquo_setting_filters
    uhook_setting_filters
  end

  def ubiquo_setting_list(context, ubiquo_settings, options = {})
    render(:partial => "shared/ubiquo/lists/standard", :locals => {
      :name => 'ubiquo_setting',
      :headers => [:key, :value],
      :rows => ubiquo_settings.collect do |setting_key|
        ubiquo_setting = get_ubiquo_setting(context, setting_key)
        {
          :columns => [
            print_key_label(ubiquo_setting),
            render_value(ubiquo_setting),
          ],
          :actions => uhook_ubiquo_setting_index_actions(ubiquo_setting),
          :id => ubiquo_setting.key
        }
      end,
      :pages => nil,
      :table_id => context,
      :hide_headers => true
    })
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

    result = render(:partial => "/ubiquo/shared/settings/#{ubiquo_setting.context}/#{ubiquo_setting.key}",
                        :locals => { :ubiquo_setting => ubiquo_setting }) rescue false
    result = render(:partial => "/ubiquo/shared/settings/#{type}",
                        :locals => { :ubiquo_setting => ubiquo_setting }) rescue false if !result
    result = render(:partial => "/ubiquo/ubiquo_settings/#{type}",
                            :locals => { :ubiquo_setting => ubiquo_setting }) rescue false if !result
    result = render(:partial => "/ubiquo/ubiquo_settings/ubiquo_setting.html.erb",
                      :locals => { :ubiquo_setting => ubiquo_setting }) if !result
    result
  end

  def render_value ubiquo_setting
    render :partial => 'form', :locals => {:ubiquo_setting => ubiquo_setting}
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

  def error_class ubiquo_setting
    ubiquo_setting.errors.present? ? " error_field" : " "
  end
end
