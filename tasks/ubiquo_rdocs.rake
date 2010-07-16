namespace :ubiquo do

  desc 'Generates rdoc documentation for all ubiquo plugins'
  task :rdocs => :environment do
    plugins = Ubiquo::Plugin.registered.keys - [ :ubiquo ] + [ :ubiquo_core ]
    plugins.each do |plugin|
      Rake::Task["doc:plugins:#{plugin}"].invoke
    end
  end

  namespace :rdocs do

    def upload_rdocs(dst_path)
      # TODO: Update rdocs path
      src_path = File.join(Rails.root, "doc/plugins/ubiquo_*")
      dst_path ||= "~/rdocs/edge"
      system("scp -r #{src_path} ubiquo@guides.ubiquo.me:#{dst_path}")
    end

    desc 'Uploads edge rdocs to the ubiquo guide server'
    task :publish_edge => :environment do
      upload_rdocs("~/rdocs/edge")
    end
    desc 'Uploads 0.7-stable rdocs to the ubiquo  guide server'
    task :publish_07stable => :environment do
      upload_rdocs("~/rdocs/0.7-stable")
    end
  end

end
