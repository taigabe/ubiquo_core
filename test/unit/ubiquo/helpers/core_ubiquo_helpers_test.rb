require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::Helpers::CoreUbiquoHelpersTest < ActionView::TestCase

  test 'ubiquo_image_path prepends ubiquo by default' do
    assert_equal 'ubiquo/image.png', ubiquo_image_path('image.png')
  end

  test 'ubiquo_image_path uses :ubiquo_path value' do
    Ubiquo::Config.set(:ubiquo_path, 'new_path')
    assert_equal 'new_path/image.png', ubiquo_image_path('image.png')
  end

  test 'ubiquo_image_tag is a wrapper for image_tag using ubiquo_image_path' do
    options = {:key => :value}
    self.expects(:ubiquo_image_path).with('image.png').returns('image_path')
    self.expects(:image_tag).with('image_path', options).returns('image_tag')
    assert_equal 'image_tag', ubiquo_image_tag('image.png', options)
  end

end
