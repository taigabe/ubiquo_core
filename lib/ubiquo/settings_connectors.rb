require 'ubiquo/settings'
module Ubiquo
  module SettingsConnectors
    autoload :Base, "ubiquo/settings_connectors/base"
    autoload :Standard, "ubiquo/settings_connectors/standard"
    autoload :I18n, "ubiquo/settings_connectors/i18n"

    def self.preload!
      Ubiquo::SettingsConnectors::Standard.preload!
      Ubiquo::Settings.initialize
      Ubiquo::Settings.add :settings_connector, :standard
    end

    def self.load!
      "Ubiquo::SettingsConnectors::#{Ubiquo::Settings[:settings_connector].to_s.classify}".constantize.load!
    end
  end
end
