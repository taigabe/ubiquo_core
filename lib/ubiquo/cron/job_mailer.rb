module Ubiquo
  module Cron
    class JobMailer < ActionMailer::Base

      def self.reloadable?() false end

      self.template_root = "#{File.dirname(__FILE__)}/views"

      def error(error_recipients, job, execution_message, error_message, sent_at = Time.now)
        app_name = Ubiquo::Config.get(:app_name)
        content_type "text/plain"
        charset 'utf-8'
        recipients error_recipients
        from Ubiquo::Config.get(:notifier_email_from)
        sent_on sent_at
        subject "[#{app_name} #{Rails.env} CRON JOB ERROR] for job: #{job}"
        body(
          :job               => job,
          :application       => app_name,
          :error_message     => error_message,
          :execution_message => execution_message
        )
      end

      private

      def app_name
        Ubiquo::Config.get(:app_name)
      end

    end
  end
end
