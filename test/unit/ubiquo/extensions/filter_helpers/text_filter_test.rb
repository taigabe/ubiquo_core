require File.dirname(__FILE__) + "/../../../../test_helper.rb"
require 'ubiquo/extensions/filter_helpers/text_filter'

class TextFilterTest < Ubiquo::Extensions::FilterHelpers::UbiquoFilterTestCase

  def setup
    @filter = TextFilter.new(@model, @context)
    @filter.configure
  end

  test "Should be able to render a text filter" do
    doc = HTML::Document.new(@filter.render).root
    assert_select doc, "input[id=filter_text]", 1
  end

  test "Should be able to get a message when the filter is set" do
    @context.params.merge!({ 'filter_text' => "prova" })
    assert_match /prova/, @filter.message.first
  end

end
