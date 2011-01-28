require 'lockfile'
require 'socket'
require 'etc'
require 'digest/md5'

module Ubiquo
  module Cron
    # Log rotation
    # http://overstimulate.com/articles/logrotate-rails-passenger
    # Check logrotate include directive
    class Job

      attr_reader :backtrace

      def initialize(logger=nil)
        preserve_stds
        @logger = logger
        @stdout = StringIO.new
        @stderr = StringIO.new
      end

      def run(task)
        log_execution_message(task)
        while_redirecting_stds do
          Lockfile(Digest::MD5.hexdigest(task), :retries => 0) do
            @invoked = true
            Rake::Task[task].invoke
          end
        end
        true
      rescue Exception => e
        @backtrace = e.backtrace
        @logger.add(Logger::ERROR, build_error_message(e)) if @logger
        false
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
          message << tabidy(stderr)
        end
        message << tabify(@backtrace) unless @backtrace.blank?
        message.join("\n")
      end

      def log_execution_message(task)
        date = Time.now.strftime("%b %d %H:%M:%S")
        hostname = Socket.gethostname
        username = Etc.getlogin
        msg = "#{date} #{hostname} #{$$} (#{username}) JOB (#{task})"
        @logger.add(Logger::INFO,msg) if @logger
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
