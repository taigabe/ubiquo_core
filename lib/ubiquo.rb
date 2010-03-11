require 'ubiquo/version'
require 'ubiquo/extensions'
require 'ubiquo/helpers'
require 'ubiquo/navigation_tabs'
require 'ubiquo/navigation_links'
require 'ubiquo/required_fields'
require 'ubiquo/adapters'

Ubiquo::Config.add(:supported_locales, [ :ca, :es, :en ])
Ubiquo::Config.add(:default_locale, :ca)

module Ubiquo
  def self.supported_locales
    Ubiquo::Config.get :supported_locales
  end
  def self.default_locale
    Ubiquo::Config.get :default_locale
  end
end
