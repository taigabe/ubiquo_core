namespace :ubiquo do
  namespace :test do
    desc "Preparation for ubiquo testing"
    task :prepare => "db:test:prepare" do
      copy_dir(Dir[Rails.root.join('vendor', 'plugins', 'ubiquo**', 'test', 'fixtures')], "/tmp/ubiquo_fixtures", :force => true, :link => true)
    end
  end

  Rake::TestTask.new(:test => "ubiquo:test:prepare") do |t|
    t.libs << "test"
    target_plugin = ENV.delete("PLUGIN") || "ubiquo**"
    t.pattern = File.join('vendor', 'plugins', target_plugin, 'test', '**', '*_test.rb')
    t.verbose = false
  end

  Rake::Task['ubiquo:test'].comment = "Run all ubiquo plugins tests"

  desc "Install ubiquo migrations and fixtures to respective folders in the app"
  task :install do
    overwrite = ENV.delete("OVERWRITE")
    overwrite = overwrite == 'true' || overwrite == 'yes'  ? true : false
    copy_dir(Dir.glob(Rails.root.join('vendor', 'plugins', 'ubiquo**', 'install')), "/", :force => overwrite)
  end

  desc "Run given command inside each plugin directory."
  task :foreach, [ :command ] do |t, args|
    ubiquo_dependencies = %w[ calendar_date_select exception_notification paperclip responds_to_parent tiny_mce ]
    plugin_directory = Rails.root.join('vendor', 'plugins')
    ubiquo_plugins = Dir.glob(File.join(plugin_directory,"ubiquo_*")).map { |file| file.split("/").last }
    plugins = ubiquo_dependencies + ubiquo_plugins
    args.with_defaults(:command => 'git pull')
    plugins.each do |plugin|
      plugin_path = File.join(plugin_directory, plugin)
      command = "cd #{plugin_path} && #{args.command}"
      $stdout.puts "\nRunning #{command}"
      system(command)
      exit 1 if $? != 0
    end
  end

  # Options accepted:
  #   force:    copy files even if target exists. Defaults to false
  #   verbose:  print results. Defaults to false
  #   link:     use softlinks instead of cp. Defaults to false
  def copy_dir(from, path = "/", options = {})
    force = options[:force]
    verbose = false || options[:verbose]
    rails_target = File.join(Rails.root, path)
    FileUtils.mkdir_p(rails_target, :verbose => verbose) unless File.exists?(rails_target)
    [from].flatten.each do |f|
      files = Dir.glob(File.join(f, "*"))
      if options[:link]
        begin
          FileUtils.ln_s(files, rails_target, :verbose => verbose, :force => force)
        rescue Errno::EEXIST
        end
      else
        # refactorable
        files.each do |file|
          file_name = File.basename(file)
          if File.directory?(file)
            copy_dir(file, File.join(path, file_name), options)
          else
            FileUtils.cp(file, rails_target, :verbose => verbose) if force || !File.exists?(File.join(rails_target, file_name))
          end
        end
      end
    end
  end

end
