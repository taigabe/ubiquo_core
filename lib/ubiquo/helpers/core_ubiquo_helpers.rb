module Ubiquo
  module Helpers
    module CoreUbiquoHelpers

      # Adds the default stylesheet tags needed for ubiquo
      # options:
      #   color: by default is red, but you can replace it calling another color
      #          css file
      #   rest of options: this helper doesn't user more options, the rest are
      #                    send to stylesheet_link_tag generic helper
      def ubiquo_stylesheet_link_tag(*sources)
        stylesheets_dir = ActionView::Helpers::AssetTagHelper::STYLESHEETS_DIR + '/ubiquo'
        options = sources.extract_options!.stringify_keys
        color = options.delete("color") || :red
        default_sources = []
        if sources.include?(:defaults)
          default_sources += [:ubiquo, :ubiquo_application, :lightwindow, :listings, color]
          default_sources += collect_asset_files("#{stylesheets_dir}", "plugins/*.css")
        end
        ubiquo_sources = (sources + default_sources).collect do |source|
          next if source == :defaults
          "ubiquo/#{source}"
        end.compact
        output = stylesheet_link_tag(ubiquo_sources, options)
        if sources.include?(:defaults)
          output += <<-eos
            <!--[if lte IE 6]>
              #{stylesheet_link_tag 'ubiquo/ubiquo_ie6'}
            <![endif]-->
          eos
        end
        output
      end

      def ubiquo_javascript_include_tag(*sources)
        javascripts_dir = ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR + '/ubiquo'
        options = sources.extract_options!.stringify_keys
        default_sources = []
        if sources.include?(:defaults)
          default_sources += [:ubiquo, :lightwindow]
          default_sources += collect_asset_files("#{javascripts_dir}", "plugins/*.js")
        end
        ubiquo_sources = (sources + default_sources).collect do |source|
          next if source == :defaults
          "ubiquo/#{source}"
        end.compact
        javascript_include_tag(ubiquo_sources, options)
      end
      
      # surrounds the block between the specified box.
      def box(name, options={}, &block)
        options.merge!(:body=>capture(&block))
        concat(render(:partial => "shared/ubiquo/boxes/#{name}", :locals => options), block.binding)
      end

      # return HTML code for required ubiquo image
      def ubiquo_image_tag(name, options={})
        options[:src] ||= ubiquo_image_path(name)
        options[:alt] ||= "Ubiquo image"
        tag('img', options)
      end

      # return path for required ubiquo image
      def ubiquo_image_path(name)
        "/images/ubiquo/#{name}"
      end

      def ubiquo_boolean_image(value)
        ubiquo_image_tag(value ? 'ok.gif' : 'ko.gif')
      end

      # Return true if string_date is a valid date representation with a
      # given format (the so-called italian format by default: %d/%m/%Y)
      def is_valid_date?(string_date, format="%d/%m/%Y")
        begin
          time = Date.strptime(string_date, format)
        rescue ArgumentError
          return false
        end
        true
      end

      # Include calendar_date_select javascript and stylesheets
      # with a default theme, basedir and locale
      def calendar_includes(options = {})
        iso639_locale = options[:locale] || I18n.locale.to_s
        CalendarDateSelect.format = options[:format] || :italian
        calendar_date_select_includes "ubiquo", :locale => iso639_locale
      end

      # Renders a message in a help block in the sidebar
      def help_block_sidebar(message)
        render :partial => '/shared/ubiquo/help_block_sidebar',
        :locals => {:message => message}
      end

      # Renders a preview
      # A preview is usually used to show the values of an instance somewhere,
      # in an unobtrusive way
      # The instance to preview is taken from params[:preview_id]
      def show_preview(model_class, options = {}, &block)
        return unless params[:preview_id]
        previewed = model_class.find(params[:preview_id], options)
        return unless previewed
        locals = {:body=>capture(previewed, &block)}
        concat(render(:partial => "shared/ubiquo/preview_box", :locals => locals))
      end

      # converts symbol to ubiquo standard table head with order_by and sort_order strings 
      def ubiquo_table_headerfy(column, klass = nil)
        name = klass.nil? ? params[:controller].split("/").last.tableize : klass

        case column
          when Symbol
            link = params.clone
            if link[:order_by] == "#{name.to_s.pluralize}.#{column.to_s}"
              link[:sort_order] = link[:sort_order] == "asc" ? "desc" : "asc"
            else
              link[:order_by] = "#{name.pluralize}.#{column.to_s}"
              link[:sort_order] = "asc"
            end
            #name.classify.human_attribute_name(column.to_s.humanize)
            #t("#{name.classify}|#{column.to_s.humanize}").humanize
            link_to name.classify.constantize.human_attribute_name(column.to_s), 
                    link, 
                    { :class => (params[:order_by] == "#{name.pluralize}.#{column.to_s}" ? 
                                (params[:sort_order] == "asc" ? "order_desc" : "order_asc") : "order" )}
          when String
            column.humanize
        end
      end
    end
  end
end
