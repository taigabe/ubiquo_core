module Ubiquo
  module Extensions
    module Helper
      def settings_tab(tabnav)
        tabnav.add_tab do |tab|
          tab.text = I18n.t("ubiquo.setting.title")
          tab.title = I18n.t("ubiquo.setting.title")
          tab.highlights_on({:controller => "ubiquo/settings"})
          tab.link = ubiquo_settings_path
        end if ubiquo_config_call :settings_permit, {:context => :ubiquo_settings}
      end
    end
  end
end
