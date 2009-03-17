module Ubiquo
  module NavigationTabs
    autoload :Tab,           'ubiquo/navigation_tabs/tab'
    autoload :NavigatorTabs, 'ubiquo/navigation_tabs/navigator_tabs'
  end
end

ActionController::Base.helper(Ubiquo::NavigationTabs::Helpers)
