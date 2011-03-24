namespace :ubiquo do
  namespace :cron do

    desc "Runs the specified task or script (logs, mails and avoids concurrency)"
    task :runner => :environment do
      task       = ENV.delete('task')
      type       = ENV.delete('type')
      debug      = ENV.delete('debug') || false
      type       = (type.strip.to_sym if type) || :task
      crontab    = Ubiquo::Cron::Crontab.instance
      recipients = crontab.mailto
      logfile    = crontab.logfile

      File.new(logfile, 'w') unless File.exist? logfile
      logger     = Logger.new(logfile, Logger::DEBUG)
      job = Ubiquo::Cron::Job.new(logger, debug, recipients)
      job.run(task,type)
    end

  end

  namespace :crontab do

    desc "Renders current crontab definition to stdout"
    task :render => :environment do
      puts Ubiquo::Cron::Crontab.instance.render
    end

    desc "Installs current crontab definition to current's user crontab (WARNING: removes all existing crontab entries)"
    task :install => :environment do
      system("crontab", "-r")  # Remove current crontab
      sleep 30                 # Wait a bit to give a chance for current jobs to finish (yeah I know, too optimistic)
      Ubiquo::Cron::Crontab.instance.install!
    end

  end

end
