namespace :ubiquo do  
  namespace :test do
    desc "Preparation for ubiquo testing"
    task :prepare => "db:test:prepare" do
      copy_dir(Dir[File.join(RAILS_ROOT, "vendor/plugins/ubiquo**/test/fixtures")], "/tmp/ubiquo_fixtures", :force => true)
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
    copy_dir(Dir.glob(File.join(RAILS_ROOT, 'vendor', 'plugins', 'ubiquo**', 'install')), "/", :force => overwrite)
  end

  desc "Run given command inside each plugin directory."
  task :foreach, [ :command ] do |t, args|
    args.with_defaults(:command => 'git pull')
    glob = File.join(RAILS_ROOT, 'vendor', 'plugins', "*/")
    plugins = Dir[ glob ].each { |e| e unless File.file? e }
    plugins.each do |plugin|
      command = "cd #{plugin} && #{args.command}"
      puts "\nRunning #{command}"
      system(command)
      exit 1 if $? != 0
    end
  end
  
  def copy_dir(from, path = "/", options = {})
    force = options[:force]
    rails_target = File.join(RAILS_ROOT, path)
    FileUtils.mkdir_p(rails_target, :verbose => true) unless File.exists?(rails_target)
    [from].flatten.each do |f|
      files = Dir.glob(File.join(f, "*"))
      files.each do |file|
        file_name = File.basename(file)
        if File.directory?(file)
          copy_dir(file, File.join(path, file_name), options)
        else
          FileUtils.cp(file, rails_target, :verbose => false) if force || !File.exists?(File.join(rails_target, file_name))
        end
      end
    end
  end
     
end
