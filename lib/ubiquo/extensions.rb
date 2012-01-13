begin
  require "rails_generator"
rescue LoadError
  puts $!
end

module Ubiquo::Extensions
  autoload :Loader, 'ubiquo/extensions/loader'

  # Load the defined extensions for +klass+ into +recipient+
  def self.load_extensions_for klass, recipient = klass
    if Loader.has_extensions?(klass.name)
      recipient.send :include, Loader.extensions_for(klass.name)
    end
  end
end

ActionController::Routing::RouteSet::Mapper.send(:include, Ubiquo::Extensions::Routing) rescue nil
Ubiquo::Extensions::Loader.append_include(:UbiquoController, Ubiquo::Extensions::DateParser)
ActionView::Base.field_error_proc = Ubiquo::Extensions::ActionView.ubiquo_field_error_proc
ActiveRecord::Base.send(:extend, Ubiquo::Extensions::ActiveRecord)

Object.send(:include, Ubiquo::Extensions::Object)
Proc.send(:include, Ubiquo::Extensions::Proc)
Array.send(:include, Ubiquo::Extensions::Array)
String.send(:include, Ubiquo::Extensions::String)

begin
  Rails::Generator::Commands::Create.send(:include, Ubiquo::Extensions::RailsGenerator::Create)
  Rails::Generator::Commands::Destroy.send(:include, Ubiquo::Extensions::RailsGenerator::Destroy)
  Rails::Generator::Commands::List.send(:include, Ubiquo::Extensions::RailsGenerator::List)
rescue NameError
  puts $!
end

if Rails.env.test?
  require 'action_controller/test_case'
  ActiveSupport::TestCase.send(:include, Ubiquo::Extensions::TestCase)
  ActionController::TestCase.send(:include, Ubiquo::Extensions::TestCase)
end

ActiveRecord::Base.send(:include, Ubiquo::Extensions::ConfigCaller)
ActiveRecord::Base.send(:extend, Ubiquo::Extensions::ConfigCaller)
ActiveRecord::Base.send(:extend, Ubiquo::Extensions::DistinctOption) rescue puts $!
Ubiquo::Extensions::Loader.append_extend(:UbiquoController, Ubiquo::Extensions::ConfigCaller)
Ubiquo::Extensions::Loader.append_include(:UbiquoController, Ubiquo::Extensions::ConfigCaller)
ActionView::Base.send(:include, Ubiquo::Extensions::ConfigCaller)
ActionView::Base.send(:extend, Ubiquo::Extensions::ConfigCaller)


ActionController::Base.helper(Ubiquo::Extensions::Helper)
ActionView::Base.send(:include, Ubiquo::Extensions::Helper)
