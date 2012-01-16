module Ubiquo
  module SettingsConnectors
    class Base < Ubiquo::Connectors::Base
      # Load all the modules that conform a connector and perform any other necessary task
      def self.preload!
        if current = Ubiquo::SettingsConnectors::Base.current_connector
          current.unload!
        end
        Ubiquo::SettingsConnectors::Base.set_current_connector self

        Ubiquo::Settings.send(:include, self::Settings)
      end

      def self.load!

        preload!

        ::UbiquoSetting.reset_column_information
        ::UbiquoSetting.send(:include, self::UbiquoSetting)

        return if validate_requirements == false
        prepare_mocks if Rails.env.test?

        #Ubiquo::Settings.initialize
        ::ActiveRecord::Base.send(:include, self::ActiveRecord::Base)
        ::Ubiquo::Extensions::Loader.append_include(:"Ubiquo::UbiquoSettingsController", self::UbiquoSettingsController)

        ::ActiveRecord::Migration.send(:include, self::Migration)

        #::UbiquoConfig::Filters::SettingFilter.send(:include, self::UbiquoHelpers::Helper)
        Ubiquo::Settings.loaded = true
        Ubiquo::Settings.regenerate_settings
        Ubiquo::Settings.load_from_backend!
      end
    end
  end
end
