module Ubiquo
  module NavigationTabs
    autoload :Tab,           'ubiquo/navigation_tabs/tab'
    autoload :NavigatorTabs, 'ubiquo/navigation_tabs/navigator_tabs'
  end
end

Ubiquo::Extensions::UbiquoAreaController.append_helper(Ubiquo::NavigationTabs::Helpers)
