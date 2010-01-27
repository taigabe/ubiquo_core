module Ubiquo
  module Helpers
    autoload :CoreUbiquoHelpers, 'ubiquo/helpers/core_ubiquo_helpers.rb'
    autoload :CorePublicHelpers, 'ubiquo/helpers/core_public_helpers.rb'    
  end
end

Ubiquo::Extensions::UbiquoAreaController.append_helper(Ubiquo::Helpers::CoreUbiquoHelpers)
Ubiquo::Extensions::UbiquoAreaController.append_helper(Ubiquo::Helpers::ShowHelpers)
ActionController::Base.helper(Ubiquo::Helpers::CorePublicHelpers)
