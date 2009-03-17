module Ubiquo
  module NavigationLinks
    autoload :Link,           'ubiquo/navigation_links/link'
    autoload :NavigatorLinks, 'ubiquo/navigation_links/navigator_links'
    autoload :Helpers,        'ubiquo/navigation_links/helpers'
  end
end

ActionController::Base.helper(Ubiquo::NavigationLinks::Helpers)
