module Ubiquo
  module Helpers
    module CoreHelpers
      def ubiquo_stylesheet_link_tags(files=['ubiquo','ubiquo_application','lightwindow'])
        files.delete 'lightwindow' unless File.exists? stylesheet_path('lightwindow')        
        files.collect do |css|
          stylesheet_link_tag "#{css}", :media => "all"
        end.join "\n"
      end

      # return javascripts with ubiquo path.
      def ubiquo_javascript_include_tags(files=['ubiquo', 'lightwindow'])
        files.collect do |js|
          javascript_include_tag "ubiquo/#{js}"
        end.join "\n"
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
      
      def help_block_sidebar(message)
        render :partial => '/shared/ubiquo/help_block_sidebar',
        :locals => {:message => message}
      end
      
      def url_for_file_attachment(object, attribute)
        if object.send("#{attribute}_is_public?")
          url_for(object.send(attribute).url)
        else
          url_for(ubiquo_attachment_url(:path => object.send(attribute).url))
        end
      end
    end
  end
end
