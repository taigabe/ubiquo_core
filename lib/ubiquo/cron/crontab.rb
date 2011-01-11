require 'tempfile'

module Ubiquo
  module Cron
    class Crontab

      cattr_accessor :instance

      attr_accessor  :mailto
      attr_accessor  :path
      attr_accessor  :env
      attr_accessor  :logfile
      attr_accessor  :lines

      def self.reloadable?() false end

      class << self

        def clear!
          self.instance = nil
        end

        def configure
          crontab = self.instance || self.new
          yield crontab
          self.instance = crontab
        end

        def schedule(namespace = Ubiquo::Config.get(:app_name))
          crontab = self.instance || self.new
          crontab.comment "Start jobs for #{namespace}"
          yield crontab
          crontab.comment "End jobs for #{namespace}"
          self.instance = crontab
        end

        def render
          self.instance.lines.join("\n")
        end

        # This methods installs the defined schedule in crontab
        # ovewriting the one installed for the user running this method.
        def install!
          crontab_schedule = self.render
          unless crontab_schedule.blank?
            schedule = Tempfile.new('crontab_schedule')
            schedule << crontab_schedule
            schedule.close
            status = system("crontab",schedule.path)
          else
            status = 0
          end
          status
        ensure
          schedule.delete if schedule
        end
      end

      def initialize
        @path     = Rails.root
        @env      = Rails.env
        @logfile  = File.join Rails.root, 'log', "cron-#{@env}.log"
        self.instance = self
        @lines    = []
      end

      def rake(schedule, task)
        parts = task.split(' ')
        job = parts.first
        rest = parts.drop(1).join(' ')
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

    end
  end
end
