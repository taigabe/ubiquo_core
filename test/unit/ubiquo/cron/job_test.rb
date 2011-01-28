require File.dirname(__FILE__) + "/../../../test_helper.rb"
require 'tempfile'
require 'socket'
require 'etc'

class Ubiquo::Cron::JobTest < ActiveSupport::TestCase

  # Things we need to handle:
  # 1) Avoid multiple execution (if possible without external dependencies). Done.
  # 2) Log results to a file (deal with log rotations). partially done.
  # 3) Send email alerts on errors (avoid multiple if possible).
  # 4) Ability to run rake or script based tasks

  # status = Open4::open4("ls -l -zxc") { |pid,stdin,stdout,stderr| puts "PID: #{pid}"; puts "STDOUT: \n#{stdout.read.strip}"; puts "STDERR: \n#{stderr.read.strip}"; }

# class Crooner
#   def self.run(task, script=false)
#     # Should we support cron runner
#     # We must redirect all output to the log file
#     # Prevent multiple execution
#     script ? eval(task) : Rake::Task[task].invoke
#   rescue Exception => e
#     puts "Ouch this failed badly #{e}"; exit 1
#   end
# end

  def setup
    @job = Ubiquo::Cron::Job.new
    Rake::Task.define_task :ubiquo_cron_test do; end
    Rake::Task.define_task :ubiquo_cron_stds_test do
      $stdout.puts "out"
      $stderr.puts "err"
    end
  end

  def teardown
    Rake.application.instance_variable_get('@tasks').delete('ubiquo_cron_test')
    Rake.application.instance_variable_get('@tasks').delete('ubiquo_cron_stds_test')
  end

  test "Should be able to run a job" do
    assert_respond_to @job, :run
    Rake::Task['ubiquo_cron_test'].expects(:invoke).returns(true)
    assert @job.run('ubiquo_cron_test')
  end

  test "Should be able to determine if a job has been executed" do
    assert_respond_to @job, :invoked?
    assert !@job.invoked?
    assert @job.run('ubiquo_cron_test')
    assert @job.invoked?
  end

  test "Should be able to get stdout, stderr of a job" do
    assert_respond_to @job, :stdout
    assert @job.run('ubiquo_cron_stds_test')
    assert_equal "out\n", @job.stdout
    assert_equal "err\n", @job.stderr
  end

  test "Should be able to log results to a specified log file" do
    logfile = Tempfile.new('ubiquo_cron_test')
    logger = Logger.new(logfile.path, Logger::DEBUG)
    job = Ubiquo::Cron::Job.new(logger)
    job.run('ubiquo_cron_stds_test')
    contents = File.read(logfile.path)
    hostname = Socket.gethostname
    username = Etc.getlogin
    date     = Time.now.strftime("%b %d")
    assert_match(/^#{date}/, contents)
    assert_match(/#{hostname}/, contents)
    assert_match(/#{username}/, contents)
    assert_match(/#{$$}/, contents)
    assert_match(/ubiquo_cron_stds_test/, contents)
  end

  test "Lockfile shouldn't fail when task has special characters" do
    assert !@job.run('/dsada/ $$$$$ \\\\\\')
    assert_respond_to @job, :stdout
    assert @job.backtrace
  end

  test "Should catch and log exceptions" do
    logfile = Tempfile.new('ubiquo_cron_test')
    logger = Logger.new(logfile.path, Logger::DEBUG)
    job = Ubiquo::Cron::Job.new(logger)
    assert_nothing_raised do
      job.run('krash')
    end
    contents = File.read(logfile.path)
    assert_match(/Don't know how to build task 'krash'/, contents)
  end

  test "Same task execution shouldn't pile up" do
    Rake::Task.define_task :ubiquo_cron_sleep_test do; sleep 2; end
    threads    = []
    task       = 'ubiquo_cron_sleep_test'
    logfile    = Tempfile.new task
    logger     = Logger.new(logfile.path, Logger::DEBUG)

    Thread.abort_on_exception = true

    2.times do
      threads << Thread.new(logger,task) { |logger,task| Ubiquo::Cron::Job.new(logger).run(task) }
    end

    threads.each { |t| t.join }

    contents = File.read(logfile.path)
    assert_match(/Exception message: surpased retries/, contents)
    assert_match(/lockfile.rb/, contents)
  end

  # TODO: Send emails when exceptions occur
  # TODO: Ability to run scripts with eval and regular commands

end
