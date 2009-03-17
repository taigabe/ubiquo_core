module Ubiquo
  module Helpers
    autoload :CoreHelpers, 'ubiquo/helpers/core_helpers.rb'
  end
end

ActionController::Base.helper(Ubiquo::Helpers::CoreHelpers)
