# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = "test.com"

Rails.backtrace_cleaner.remove_silencers!

# Run any available migration
ActiveRecord::Migrator.migrate File.expand_path("../../install/db/migrate/", __FILE__)

if ActiveRecord::Base.connection.class.to_s == "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
  ActiveRecord::Base.connection.client_min_messages = "ERROR"
end

require File.dirname(__FILE__) + '/relation_helper'
require 'rake' # For cron job testing


def enable_settings_override
  Ubiquo::Settings[:ubiquo][:settings_overridable] = true
end

def disable_settings_override
  Ubiquo::Settings[:ubiquo][:settings_overridable] = false
end

class ActiveSupport::TestCase
  include Ubiquo::Engine.routes.url_helpers
  include Rails.application.routes.mounted_helpers
end

