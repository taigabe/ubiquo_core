namespace :ubiquo do
  namespace :cron do

    desc "Runs the specified task or script (logs, mails and avoids concurrency)"
    task :runner => :environment do
      task    = ENV.delete('task')
      type    = ENV.delete('type')
      debug   = ENV.delete('debug') || false
      type    = (type.strip.to_sym if type) || :task
      krontab = Ubiquo::Cron::Crontab
      krontab.configure { |c| } unless krontab.instance
      crontab    = krontab.instance
      recipients = crontab.mailto
      logfile    = crontab.logfile
      File.new(logfile, 'w') unless File.exist? logfile
      logger     = Logger.new(logfile, Logger::DEBUG)
      job = Ubiquo::Cron::Job.new(logger, debug, recipients)
      job.run(task,type)
    end

  end
end
