require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class LinkTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  
  def test_should_create_link
    assert_difference 'Link.count' do
      link = create_link
      assert !link.new_record?, "#{link.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_title
    assert_no_difference 'Link.count' do
      link = create_link :title => ""
      assert link.errors.on(:title)
    end
  end

  def test_should_require_url
    assert_no_difference 'Link.count' do
      link = create_link :url => ""
      assert link.errors.on(:url)
    end
  end

  def test_should_require_target
    assert_no_difference 'Link.count' do
      link = create_link :target => ""
      assert link.errors.on(:target)
    end
  end

  def test_target_should_validate_to_a_correct_value
    link = create_link
    assert link.valid?
    link.target = "nonvalid"
    assert !link.valid? && link.errors.on(:target)
    link.target = "_blank"
    assert link.valid?
    link.target = "_self"
    assert link.valid?
  end

  def test_check_protocol_should_fix_url_before_saving
    link = create_link(:url => 'webpage.com')
    assert link.url == 'http://webpage.com'  
    link = create_link(:url => '/a/path')
    assert link.url == '/a/path'  
    link = create_link(:url => 'ftp://server.com')
    assert link.url == 'ftp://server.com'  
  end
  
  private
  
  def create_link(options = {})
    default_options = {
      :title => "test link", 
      :url => "http://www.gnuine.com", 
      :target => "_blank",
      :linkable_id => 1,
      :linkable_type => 'Article',
    }
    Link.create(default_options.merge(options))
  end

end
