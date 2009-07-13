require File.dirname(__FILE__) + "/../../test_helper.rb"
class Ubiquo::AttachmentControllerTest < ActionController::TestCase
  def test_should_not_be_able_to_request_attachements_outside_the_private_path
    assert_raises ActiveRecord::RecordNotFound do
      get(:show, { :path => '../config/routes.rb'})
    end
  end
  
  def test_should_be_able_to_obtain_attachements_inside_private_path_when_logged_in
    protected_path = File.join(RAILS_ROOT, Ubiquo::Config.get(:attachments)[:private_path])
    dummy_file = File.join(protected_path, 'dummy.html')
    File.open(dummy_file, 'w')
    get(:show, { :path => 'dummy.html' })
    assert_response :success
  ensure
    File.delete(dummy_file)
  end
  
  def test_should_not_be_able_to_obtain_attachment_when_not_logged_in
    session[:ubiquo_user_id] = nil
    get(:show, { :path => 'dummy' })
    assert_redirected_to :ubiquo_login
  end
end
