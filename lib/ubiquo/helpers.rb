module Ubiquo
  module Helpers
  end
end

Ubiquo::Extensions::UbiquoAreaController.append_helper(Ubiquo::Helpers::CoreUbiquoHelpers)
Ubiquo::Extensions::UbiquoAreaController.append_helper(Ubiquo::Helpers::ShowHelpers)
ActionController::Base.helper(Ubiquo::Helpers::CorePublicHelpers)
