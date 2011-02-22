module Ubiquo
  module NavigationLinks
  end
end

Ubiquo::Extensions::UbiquoAreaController.append_helper(Ubiquo::NavigationLinks::Helpers)
