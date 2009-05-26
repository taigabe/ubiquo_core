module Ubiquo
  module Helpers
    autoload :CoreHelpers, 'ubiquo/helpers/core_helpers.rb'
  end
end

Ubiquo::Extensions::UbiquoAreaController.append_helper(Ubiquo::Helpers::CoreHelpers)
