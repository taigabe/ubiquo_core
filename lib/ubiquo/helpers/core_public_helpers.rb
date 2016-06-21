module Ubiquo
  module Helpers
    module CorePublicHelpers
      # Return a url for a file_attachement
      #   object => instance that owns the media
      #   attribute => name of the file_attachment field
      #   style => paperclip style
      def url_for_file_attachment(object, attribute, style = nil)
        if object.send("#{attribute}_is_public?")
          url_for(object.send(attribute).url(style))
        else
          protected_path = Rails.root.join(Ubiquo::Settings.get(:attachments)[:private_path])
          path = object.send(attribute).path(style)
          relative_path = path.split(protected_path).last
          CGI::unescape(ubiquo_attachment_url(:path => relative_path))
        end
      end

      def html_unescape(s)
        s = s.to_s
        ERB::Util::HTML_ESCAPE.each do |special, value|
          s.gsub!(value, special)
        end
        s
      end
    end
  end
end
