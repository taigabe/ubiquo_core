require 'ubiquo/version'
require 'ubiquo/extensions'
require 'ubiquo/filters'
require 'ubiquo/helpers'
require 'ubiquo/navigation_tabs'
require 'ubiquo/navigation_links'
require 'ubiquo/required_fields'
require 'ubiquo/filtered_search'
require 'ubiquo/adapters'
require 'ubiquo/relation_selector'

Ubiquo::Settings.add(:supported_locales, [ :ca, :es, :en ])
Ubiquo::Settings.add(:default_locale, :ca)

module Ubiquo
  def self.supported_locales
    Ubiquo::Settings.get :supported_locales
  end
  def self.default_locale
    Ubiquo::Settings.get :default_locale
  end
end
