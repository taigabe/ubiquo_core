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
    uhook_get_ubiquo_setting(context, ubiquo_setting_key)
  end      
  
  def print_key_label ubiquo_setting
    uhook_print_key_label ubiquo_setting
  end
  
  def translate_key_name context, key
    I18n.t!("ubiquo.ubiquo_settings.#{context}.#{key}.name") rescue key
  end
  
  def translate_context_name context
    I18n.t!("ubiquo.ubiquo_settings.#{context}.name") rescue context
  end  

end
