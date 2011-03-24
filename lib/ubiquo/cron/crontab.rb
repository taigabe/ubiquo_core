module Ubiquo
  module Cron
    class Crontab

      include Singleton

      attr_accessor  :mailto
      attr_accessor  :path
      attr_accessor  :env
      attr_accessor  :logfile

      def self.schedule(*args, &block)
        self.instance.schedule(*args, &block)
      end

      def rake(schedule, task)
        parts = task.split(' ')
        job = parts.first
        # rest = parts.drop(1).join(' ')
        rest = parts[1..-1].join(' ')
        cron_job = "#{schedule} /bin/bash -l -c \"cd #{self.path} && RAILS_ENV=#{self.env} rake ubiquo:cron:runner task=\'#{job}\' #{rest} --silent 2>&1\""
        @lines << cron_job
      end

      def runner(schedule, task)
        cron_job = "#{schedule} /bin/bash -l -c \"cd #{self.path} && RAILS_ENV=#{self.env} rake ubiquo:cron:runner task=\'#{task}\' type='script' --silent 2>&1\""
        @lines << cron_job
      end

      def command(schedule, command)
        @lines << "#{schedule} #{command}"
      end

      def comment(comment)
        @lines << "### #{comment} ###"
      end

      def clear!
        initialize
      end

      def render
        return "" if just_comments?
        @lines.join("\n")
      end

      # This methods installs the defined schedule in crontab
      # ovewriting the one installed for the user running this method.
      def install!
        schedule = render
        unless schedule.blank?
          file = Tempfile.new('schedule')
          file << schedule
          file.close
          status = system("crontab",file.path)
        else
          status = 0
        end
        status
      ensure
        file.delete if file
      end

      def schedule(namespace = Ubiquo::Config.get(:app_name), &block)
        comment "Start jobs for #{namespace}"
        block.call(self)
        comment "End jobs for #{namespace}"
        self
      end

      private

      def initialize
        @mailto   = nil
        @path     = Rails.root
        @env      = Rails.env
        @logfile  = File.join Rails.root, 'log', "cron-#{@env}.log"
        @lines    = []
      end

      def just_comments?
        @lines.inject(true) do |result, line|
          result && line.match(/^#/)
        end
      end

    end
  end
end
