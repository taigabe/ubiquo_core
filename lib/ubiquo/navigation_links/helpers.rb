#= Navigator tabs helper methods
#
#This library add methods to create navigation links sections
#
module Ubiquo
  module NavigationLinks
    module Helpers

      # Render a partial view that contains navigaton links elements
      #
      # In view file:
      # <%= render_navigation_links_section :configuration %>
      #
      # renders "navigators/configuration_navlinks" partial
      #
      # :options
      # ===
      #   :partial => specify the view directory for partial file
      def render_navigation_links_section(navlinks_file_name, options = {})
        partial_template = options[:partial] || "navigators/#{navlinks_file_name}_navlinks"
        render :partial => partial_template
      end

      # Creates a Navigator instance and send it to the view to add tabs in it
      def create_link_navigator (options = {}, &block)
        navigator = NavigatorLinks.new(options)
        block.call(navigator)
        navigator
      end


      # Render a list of links with html common options :id and :class
      # ( the navigator must be configured previously with 'create_link_navigator' method )
      #
      def render_link_navigator(navigator, options = {})
        return if navigator.links.empty?
        navigator.html_options[:id]    ||= options[:id]
        navigator.html_options[:class] ||= options[:class]
        content_tag(:ul, navigator.html_options) do
          navigator.links.each do |link|
            li_options = {}
            li_options[:id] = "#{link.id}" if link.id
            li_options[:class] = link.class ? "#{link.class}" : ""
            if link.is_highlighted?(params) && link.highlight_option_active
              li_options[:class] += " #{link.highlighted_class}" if link.highlighted_class
            elsif link.is_disabled?
              li_options[:class] += " #{link.disabled_class}" if link.disabled_class
            end
            li_options[:class] = nil if li_options[:class].blank?
            item_content = if !link.is_disabled? && !link.url.blank?
              link_to(link.text, link.url, link.html)
            else
              content_tag('span', link.text, link.html)
            end
            concat(content_tag(:li, item_content, li_options))
          end
        end
      end
    end
  end
end
