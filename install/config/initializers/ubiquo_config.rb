Ubiquo::Config.add do |config|
  config.app_name = "your_app" # Ubiquo::Config.get(:app_name)
  config.app_title = "Your app" # Ubiquo::Config.get(:app_title)
  config.app_description = "Your app description" # Ubiquo::Config.get(:app_description)
end
#Exception notification
ExceptionNotifier.exception_recipients = %w( programadors@gnuine.com )
ExceptionNotifier.sender_address = %("Application Error" <rails@alpi03.gnuine.com>)
ExceptionNotifier.email_prefix = "[#{Ubiquo::Config.get(:app_name)} #{RAILS_ENV} ERROR] "
