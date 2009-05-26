module Ubiquo
  module NavigationLinks
    autoload :Link,           'ubiquo/navigation_links/link'
    autoload :NavigatorLinks, 'ubiquo/navigation_links/navigator_links'
    autoload :Helpers,        'ubiquo/navigation_links/helpers'
  end
end

Ubiquo::Extensions::UbiquoAreaController.append_helper(Ubiquo::NavigationLinks::Helpers)
