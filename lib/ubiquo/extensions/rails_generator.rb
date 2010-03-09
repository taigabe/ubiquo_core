module Ubiquo
  module Extensions
    module RailsGenerator
      module Create
        # Modify routes.rb and include the namespaced resources
        def namespaced_route_resources(namespace, *resources)
          resource_list = resources.map { |r| r.to_sym.inspect }.join(', ')
          sentinel = "map.namespace :#{namespace} do |#{namespace}|"

          logger.route "#{namespace}.resources #{resource_list}"
          unless options[:pretend]
            gsub_file 'config/routes.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
              "#{match}\n    #{namespace}.resources #{resource_list}\n"
            end
          end
        end
        # Add ubiquo tab
        def ubiquo_tab(name)
          sentinel = 'navigator_left = create_tab_navigator(:id => "contents_tabnav", :tab_options => {}) do |navigator|'
          unless options[:pretend]
            gsub_file 'app/views/navigators/_main_navtabs.html.erb', /(#{Regexp.escape(sentinel)})/mi do |match|
    "#{match}\n # Begin #{name} tab
     navigator.add_tab do |tab|
       tab.text = t('application.#{name}')
       tab.title = t('application.goto', :place => '#{name}')
       tab.link = ubiquo_#{name}_path
       tab.highlights_on({:controller => 'ubiquo/#{name}')
       tab.highlighted_class = 'active'
     end
     # End #{name} tab"
            end
          end
        end
      end
      module Destroy
        # Modify routes.rb deleting the namespaced resources
        def namespaced_route_resources(namespace, *resources)
          resource_list = resources.map { |r| r.to_sym.inspect }.join(', ')
          look_for = "\n    #{namespace}.resources #{resource_list}\n"
          logger.route "#{namespace}.resources #{resource_list}"
          gsub_file 'config/routes.rb', /(#{look_for})/mi, ''
        end
      end
      module List
        def namespaced_route_resources(namespace, *resources)
          resource_list = resources.map { |r| r.to_sym.inspect }.join(', ')
          logger.route "#{namespace}.resources #{resource_list}"
        end
      end
    end
  end
end
