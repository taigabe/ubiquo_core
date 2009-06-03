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
