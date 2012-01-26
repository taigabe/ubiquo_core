map.namespace :ubiquo do |ubiquo|
  ubiquo.home '', :controller => "home", :action => "index"
  ubiquo.with_options :controller => "attachment", :action => "show", :conditions => {:method => :get} do |attachment|
    attachment.attachment "/attachment/*path"
  end
  ubiquo.resources :ubiquo_settings
end

if Rails.env.test?
  map.connect 'default_mime_responds_route_index', :controller => 'default_mime_responds', :action => 'index'
  map.connect 'default_mime_responds_route_show', :controller => 'default_mime_responds', :action => 'show'
end
