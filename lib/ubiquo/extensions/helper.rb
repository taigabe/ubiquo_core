module Ubiquo
  module Extensions
    module Helper
      def ubiquo_settings_tab(tabnav)
        tabnav.add_tab do |tab|
          tab.text = I18n.t("ubiquo.ubiquo_setting.title")
          tab.title = I18n.t("ubiquo.ubiquo_setting.title")
          tab.highlights_on({:controller => "ubiquo/ubiquo_settings"})
          tab.link = ubiquo_ubiquo_settings_path
        end if ubiquo_config_call :settings_permit, {:context => :ubiquo}
      end
    end
  end
end
