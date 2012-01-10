module Ubiquo

  class Engine < Rails::Engine
    config.paths["lib"].autoload!
    config.autoload_paths << "#{config.root}/install/app/controllers"

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

      Ubiquo::Config.add(:supported_locales, [ :ca, :es, :en ])
      Ubiquo::Config.add(:default_locale, :ca)
    end
  end

  def self.supported_locales
    Ubiquo::Config.get :supported_locales
  end
  def self.default_locale
    Ubiquo::Config.get :default_locale
  end
end
