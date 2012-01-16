module Ubiquo

  class Engine < Rails::Engine
    module Base
      def self.included plugin
        plugin.class_eval do
          # Configure some default autoload paths
          config.paths["lib"].autoload!
          config.autoload_paths << "#{config.root}/install/app/controllers"

          isolate_namespace Ubiquo

          # Define ubiquo_xxx:install task
          rake_tasks do
            namespace railtie_name do
              desc "Install files from #{railtie_name} to application"
              task :install do
                ENV["FROM"] = railtie_name
              end
            end
          end

          # All our initializers will be run by default before the app initializers
          class << self
            def initializer_with_default_before(name, opts = {}, &blk)
              unless opts[:after] or opts[:before]
                opts[:before] = :load_config_initializers
              end
              initializer_without_default_before(name, opts, &blk)
            end
            alias_method_chain :initializer, :default_before
          end

        end
      end
    end
    include Ubiquo::Engine::Base

    initializer :load_extensions do
      require 'ubiquo/version'
      require 'ubiquo/plugin'
      require 'ubiquo/extensions'
      require 'ubiquo/filters'
      require 'ubiquo/helpers'
      require 'ubiquo/navigation_tabs'
      require 'ubiquo/navigation_links'
      require 'ubiquo/required_fields'
      require 'ubiquo/filtered_search'
      require 'ubiquo/adapters'
      require 'ubiquo/relation_selector'
      require 'ubiquo/permissions_interface'

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
