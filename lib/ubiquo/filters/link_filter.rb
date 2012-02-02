module Ubiquo
  module Filters
    class LinkFilter < SelectFilter

      def render
        lateral_filter(@options) do |keepable_params|
          filter_field = @options[:field]
          @context.content_tag(:div, :id => 'links_filter_content') do
            @context.content_tag(:ul) do
              @options[:collection].inject("".html_safe) do |result, object|
                css_class = (@context.params[filter_field].to_s) == object.send(@options[:id_field]).to_s ? "on" : "off"
                name = object.send(@options[:name_field])
                keepable_params.update(filter_field => object.send(@options[:id_field]))
                result += @context.content_tag(:li) do
                  url_for_options = @context.params.merge(keepable_params[:url_for_options] || {})
                  @context.link_to name, url_for_options, :class => css_class
                end
              end
            end
          end
        end
      end

    end
  end
end
