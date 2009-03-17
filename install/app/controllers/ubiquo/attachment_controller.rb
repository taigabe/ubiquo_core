class Ubiquo::AttachmentController < UbiquoAreaController
  def show
    protected_path = Ubiquo::Config.get(:attachments)[:private_path]
    path = File.join(RAILS_ROOT, protected_path, params[:path])
    send_multimedia(path, :x_sendfile => Ubiquo::Config.get(:attachments)[:use_x_send_file])   
  end
  
  protected 
  
  def send_multimedia(absolute_path, options = {})
    raise ActiveRecord::RecordNotFound unless absolute_path && File.exists?(absolute_path)
    filename = File.basename(absolute_path)
    case File.extname(filename).downcase      
      when ".jpg", ".jpeg"
        content_type = "image/jpeg"
        disposition = "inline"
      when ".wmv"
        content_type = "video/x-ms-wmv"
        disposition = "attachment"
      when ".avi"
        content_type = "video/avi"
        disposition = "attachment"
      when ".mov"
        content_type = "video/quicktime"
        disposition = "attachment"
      when ".mp4"
        content_type = "video/mp4"
        disposition = "attachment"
      when ".mpg"
        content_type = "video/mpeg"
        disposition = "attachment"      
      when ".flv"
        content_type = "video/x-flv"
        disposition = "attachment"        
      when ".zip"
        content_type = "application/zip"
        disposition = "attachment"
      else
        content_type = "application/octet-stream"
        disposition = "attachment"
    end

    response.headers["Content-type"] = content_type
    response.headers['Content-length'] = File.size(absolute_path)
    response.headers['Cache-Control'] = 'must-revalidate'

    send_file absolute_path, {:filename => filename, :type => content_type, :disposition => disposition}.merge(options)
  end
end
