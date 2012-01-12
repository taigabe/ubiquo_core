require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::Extensions::ObjectTest < ActiveSupport::TestCase
  test "should parse object to boolean" do
    ["true", true, 1, "1", "test", [], Ubiquo].each do |obj|
      assert_equal true, obj.to_bool
    end
    ["false", false, 0, "0", nil].each do |obj|
      assert_equal false, obj.to_bool
    end
  end
end
