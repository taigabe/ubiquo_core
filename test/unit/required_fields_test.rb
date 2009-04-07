require File.dirname(__FILE__) + "/../test_helper.rb"

class Ubiquo::RequiredFieldsTest < ActiveSupport::TestCase
  include Ubiquo::Extensions::ConfigCaller
  def test_add_expected_required_fields
    assert_equal [:name, :title], TestModel.required_fields
  end
  
  def test_add_expected_required_fields_in_iherited_models
    assert_equal [:name, :title, :surname, :subtitle], InheritedModel.required_fields
  end
end

class TestModel < ActiveRecord::Base
  validates_presence_of :name, :if => lambda{|m| m.id == 1}
  required_fields :title
end

class InheritedModel < TestModel
  validates_presence_of :surname, :if => lambda{|m| m.id == 1}
  required_fields :subtitle
end
