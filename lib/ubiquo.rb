require 'ubiquo/version'
require 'ubiquo/extensions'
require 'ubiquo/helpers'
require 'ubiquo/navigation_tabs'
require 'ubiquo/navigation_links'
require 'ubiquo/required_fields'
require 'ubiquo/adapters'

Ubiquo::Config.add(:supported_locales, %w[ ca es en ])

class Ubiquo
  def self.supported_locales
    Ubiquo::Config.get :supported_locales
  end
end
