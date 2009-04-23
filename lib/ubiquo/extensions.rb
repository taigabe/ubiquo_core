require 'action_controller/test_case'
require "rails_generator"

module Ubiquo
  module Extensions
    autoload :Routing,               'ubiquo/extensions/routing'
    autoload :ActiveRecord,          'ubiquo/extensions/active_record'
    autoload :DateParser,            'ubiquo/extensions/date_parser'
    autoload :Array,                 'ubiquo/extensions/array'
    autoload :String,                'ubiquo/extensions/string'
    autoload :TestImprovements,      'ubiquo/extensions/test_improvements'
    autoload :FiltersHelper,         'ubiquo/extensions/filters_helper'
    autoload :ActionView,            'ubiquo/extensions/action_view'
    autoload :ConfigCaller,          'ubiquo/extensions/config_caller'
    
    module RailsGenerator
      [ :Create, :Destroy, :List ].each { |m| autoload m, 'ubiquo/extensions/rails_generator' }
    end
  end
end

ActionController::Routing::RouteSet::Mapper.send(:include, Ubiquo::Extensions::Routing)
ActionController::Base.send(:include, Ubiquo::Extensions::DateParser)
ActionController::Base.helper(Ubiquo::Extensions::FiltersHelper)
ActionView::Base.field_error_proc = Ubiquo::Extensions::ActionView.ubiquo_field_error_proc
ActiveRecord::Base.send(:extend, Ubiquo::Extensions::ActiveRecord)
Array.send(:include, Ubiquo::Extensions::Array)
String.send(:include, Ubiquo::Extensions::String)

Rails::Generator::Commands::Create.send(:include, Ubiquo::Extensions::RailsGenerator::Create)
Rails::Generator::Commands::Destroy.send(:include, Ubiquo::Extensions::RailsGenerator::Destroy)
Rails::Generator::Commands::List.send(:include, Ubiquo::Extensions::RailsGenerator::List)

if RAILS_ENV == 'test'
  ActiveSupport::TestCase.send(:include, Ubiquo::Extensions::TestImprovements)
  ActionController::TestCase.send(:include, Ubiquo::Extensions::TestImprovements)
end


ActiveRecord::Base.send(:include, Ubiquo::Extensions::ConfigCaller)
ActiveRecord::Base.send(:extend, Ubiquo::Extensions::ConfigCaller)
ActionController::Base.send(:extend, Ubiquo::Extensions::ConfigCaller)
ActionController::Base.send(:include, Ubiquo::Extensions::ConfigCaller)
ActionView::Base.send(:include, Ubiquo::Extensions::ConfigCaller)
ActionView::Base.send(:extend, Ubiquo::Extensions::ConfigCaller)
