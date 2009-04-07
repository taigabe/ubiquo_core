module Ubiquo
  module RequiredFields
    autoload :ActiveRecord, "ubiquo/required_fields/active_record.rb"
    autoload :Validations, "ubiquo/required_fields/validations.rb"
    autoload :FormHelper, "ubiquo/required_fields/form_helper.rb"
    autoload :FormTagHelper, "ubiquo/required_fields/form_tag_helper.rb"
  end
end

ActiveRecord::Base.send :include, Ubiquo::RequiredFields::ActiveRecord
ActiveRecord::Validations::ClassMethods.send :include, Ubiquo::RequiredFields::Validations
ActionView::Helpers::FormHelper.send :include, Ubiquo::RequiredFields::FormHelper
ActionView::Helpers::FormTagHelper.send :include, Ubiquo::RequiredFields::FormTagHelper
