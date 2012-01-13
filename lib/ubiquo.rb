module Ubiquo

  class Engine < Rails::Engine
    config.paths["lib"].autoload!
    config.autoload_paths << "#{config.root}/install/app/controllers"
    isolate_namespace Ubiquo
    initializer :load_extensions do

      require 'ubiquo/version'
      require 'ubiquo/extensions'
      require 'ubiquo/filters'
      require 'ubiquo/helpers'
      require 'ubiquo/navigation_tabs'
      require 'ubiquo/navigation_links'
      require 'ubiquo/required_fields' rescue puts $!
      require 'ubiquo/filtered_search'
      require 'ubiquo/adapters'
      require 'ubiquo/relation_selector'

    end

    initializer :register_ubiquo_plugin do
      require 'ubiquo/init_settings.rb'
    end

    initializer :load_settings_connector do
      if Ubiquo::Plugin.registered[:ubiquo_i18n]
        Ubiquo::Settings[:settings_connector] = :i18n
      end
      Ubiquo::SettingsConnectors.load!
    end
  end

  def self.supported_locales
    Ubiquo::Settings.get :supported_locales
  end
  def self.default_locale
    Ubiquo::Settings.get :default_locale
  end
end
