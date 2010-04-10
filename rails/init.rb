require 'ubiquo'

Ubiquo::Plugin.register(:ubiquo, directory, config)

Ubiquo::Config.add(:elements_per_page, 10)

Ubiquo::Config.add(:max_size_for_links_filter, 5)

# :model_groups is a hash :group_name => %w{table names in group}
Ubiquo::Config.add(:model_groups, {})
Ubiquo::Config.add(:attachments, {
  :visibility => :public,
  :public_path => "public",
  :private_path => "protected",
  :use_x_send_file => RAILS_ENV == "development" ? false : true,
})

Ubiquo::Config.add(:required_field_class, 'required_field')
