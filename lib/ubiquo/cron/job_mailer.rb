module Ubiquo
  module Cron

    # Sends mail with cron job errors.
    class JobMailer < ActionMailer::Base
      default :from => Ubiquo::Settings.get(:notifier_email_from),
              :return_path => Ubiquo::Settings.get(:notifier_email_from),
              :charset => "UTF-8", :content_type => "text/plain"

      def self.reloadable?() false end

      # Sends email with cron job error.
      #
      # ==== Attributes
      #
      # * +error_recipients+ - who to mail.
      # * +job+ - job (task) name.
      # * +execution_message+ - string with information about
      #   execution of the job.
      # * +error_message- string with the error message.
      def error(error_recipients, job, execution_message, error_message)
        @application = Ubiquo::Settings.get(:app_name)
        @job = job
        @error_message = error_message
        @execution_message = execution_message

        subject = "[#{app_name} #{Rails.env} CRON JOB ERROR] for job: #{job}"
        mail(:to => error_recipients,
             :subject => subject)
      end

      private

      def app_name
        Ubiquo::Settings.get(:app_name)
      end

    end
  end
end
