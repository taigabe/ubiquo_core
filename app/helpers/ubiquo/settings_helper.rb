module Ubiquo::SettingsHelper

  def setting_filters
    uhook_setting_filters
  end
  
  def setting_list(context, settings, options = {})
    render(:partial => "shared/ubiquo/lists/standard", :locals => {
      :name => 'setting',
      :headers => [:key, :value],
      :rows => settings.collect do |setting_key|    
        setting = get_setting(context, setting_key)
        {
          :columns => [
            print_key_label(setting),
            render_value(setting),
          ],
          :actions => uhook_setting_index_actions(setting),
          :id => setting.key
        }
      end,
      :pages => nil,
      :table_id => context,
      :hide_headers => true
    })
  end

  def render_template_type setting
    type = setting.class.name.gsub('Setting', '').underscore
    type = Setting.name.underscore if type.blank?

    result = render(:partial => "/ubiquo/shared/settings/#{setting.context}/#{setting.key}",
                        :locals => { :setting => setting }) rescue false
    result = render(:partial => "/ubiquo/shared/settings/#{type}",
                        :locals => { :setting => setting }) rescue false if !result
    result = render(:partial => "/ubiquo/settings/#{type}",
                            :locals => { :setting => setting }) rescue false if !result
    result = render(:partial => "/ubiquo/settings/setting.html.erb",
                      :locals => { :setting => setting }) if !result
    result
  end

  def render_value setting
    render :partial => 'form', :locals => {:setting => setting}
  end
  
  def get_setting(context, setting_key)
    uhook_get_setting(context, setting_key)
  end      
  
  def print_key_label setting
    uhook_print_key_label setting
  end

end
