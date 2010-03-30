require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::Extensions::ActiveRecordTest < ActiveSupport::TestCase

  def test_should_have_a_paginate
    assert ActiveRecord::Base.methods.include?('paginate')
  end
  
  def test_should_have_an_ubiquo_paginate
    assert ActiveRecord::Base.methods.include?('ubiquo_paginate')
  end
    
  def test_file_attachment_should_clone_given_options_when_defining_paperclip_styles
    original_styles = {
        :style_name => {
          :processors => [:example_processor],
        }
    }

    Object.const_set('TestFileAttachmentClass', Class.new(ActiveRecord::Base))
    TestFileAttachmentClass.class_eval do
      file_attachment :file, :styles => original_styles
    end

    current_styles = TestFileAttachmentClass.attachment_definitions[:file][:styles]

    assert_not_equal original_styles.object_id, current_styles.object_id
    assert original_styles[:style_name][:processors] # not deleted

    # cleanup
    Object.send(:remove_const, 'TestFileAttachmentClass')
  end
end
