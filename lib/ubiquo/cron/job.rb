require 'lockfile'
require 'socket'
require 'etc'
require 'digest/md5'

module Ubiquo
  module Cron

    class Job

      attr_reader :backtrace

      def initialize(logger=nil, debug = false, recipients = Ubiquo::Cron::Crontab.instance.mailto)
        preserve_stds
        @logger     = logger
        @recipients = recipients
        @stdout     = StringIO.new
        @stderr     = StringIO.new
        @debug      = debug
      end

      def run(task, type = :task)
        start = Time.now
        execution_message = build_execution_message(task)
        while_redirecting_stds do
          lockfile = File.join Rails.root, "tmp", "cron-" + Digest::MD5.hexdigest(task)
          Lockfile(lockfile, :retries => 0) do
           @invoked = true
            case type
            when :task then Rake::Task[task].invoke
            when :script then eval(task)
            end
          end
        end
        true
      rescue Exception => e
        @backtrace = e.backtrace
        error_message = build_error_message(e)
        Ubiquo::Cron::JobMailer.deliver_error(@recipients, task, execution_message, error_message) if @recipients
        false
      ensure
        execution_message << " (#{Time.now - start} seconds elapsed)"
        # TODO: Fix this to use only a logger.add call
        @logger.add(Logger::INFO, execution_message) if @logger
        @logger.add(Logger::ERROR, error_message) if @logger && error_message
        @logger.add(Logger::DEBUG, build_debug_message ) if @logger && @debug && !error_message
      end

      def invoked?
        @invoked
      end

      def stdout
        @stdout.string
      end

      def stderr
        @stderr.string
      end

      private

      def tabify(item)
        item = item.split("\n") if item.kind_of? String
        item.map { |i| "    " + i }.join("\n")
      end

      def build_error_message(e)
        message = []
        message << tabify("Exception message: #{e.message}") if e.message
        unless stdout.blank?
          message << tabify("Stdout: ")
          message << tabify(stdout)
        end
        unless stderr.blank?
          message << tabify("Stderr: ")
          message << tabify(stderr)
        end
        message << tabify(@backtrace) unless @backtrace.blank?
        message.join("\n")
      end

      def build_debug_message
        message = []
        unless stdout.blank?
          message << tabify("DEBUG Standard output: ")
          message << tabify(stdout)
        end
        unless stderr.blank?
          message << tabify("DEBUG Standard error: ")
          message << tabify(stderr)
        end
        message.join("\n")
        # Return nil if empty
      end

      def build_execution_message(task)
        date = Time.now.strftime("%b %d %H:%M:%S")
        hostname = Socket.gethostname
        username = Etc.getpwuid(Process.uid).name
        msg = "#{date} #{hostname} #{$$} (#{username}) JOB (#{task})"
      end

      def preserve_stds
        @prev_stderr = $stderr
        @prev_stdout = $stdout
      end

      def while_redirecting_stds
        grab_stds
        yield
      ensure
        restore_stds
      end

      def grab_stds
        $stdout = @stdout
        $stderr = @stderr
      end

      def restore_stds
        $stdout = @prev_stdout
        $stderr = @prev_stderr
      end

    end
  end
end
