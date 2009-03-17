module Ubiquo
  module Extensions
    module ConfigCaller
      def ubiquo_config_call(key, options = {})
        context = options.is_a?(Hash) && options.delete(:context)
        
        config = (context ? Ubiquo::Config.context(context) : Ubiquo::Config)
        config.call(key, self, options)
      end
    end
  end
end
