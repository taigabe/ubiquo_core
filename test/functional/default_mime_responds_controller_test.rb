require File.dirname(__FILE__) + "/../test_helper.rb"

module DefaultMimeResponds
  DEFAULT_MIME_RESPONDS_COLLECTION = (1..10).map{ |i| OpenStruct.new(:id => i, :name => "name_#{i}")}
end

class DefaultMimeRespondsControllerTest < ActionController::TestCase
  test "should respond default js response for index" do
    get :index, :format => 'js'
    assert_equal JSON.parse(@response.body), JSON.parse(DefaultMimeResponds::DEFAULT_MIME_RESPONDS_COLLECTION.to_json)
  end

  test "should respond default js response for show" do
    get :show, :format => 'js'
    assert_equal JSON.parse(@response.body), JSON.parse(DefaultMimeResponds::DEFAULT_MIME_RESPONDS_COLLECTION.first.to_json)
  end
end

class DefaultMimeRespondsController < UbiquoController
  def index
    @default_mime_responds = DefaultMimeResponds::DEFAULT_MIME_RESPONDS_COLLECTION
    respond_to do |format|
      format.html
    end
  end

  def show
    @default_mime_respond = DefaultMimeResponds::DEFAULT_MIME_RESPONDS_COLLECTION.first
    respond_to do |format|
      format.html
    end
  end
end
