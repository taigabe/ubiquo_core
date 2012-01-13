Ubiquo::Engine.routes.draw do
  match "" => "home#index", :via => :get, :as => :home
  resources :ubiquo_settings
end
