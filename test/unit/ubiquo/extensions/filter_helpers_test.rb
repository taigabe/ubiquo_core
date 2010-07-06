# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../../test_helper.rb"
require 'ubiquo/extensions/filter_helpers'
require 'ubiquo/extensions/filter_helpers/boolean_filter'

# A helper class sets a proper context to be able to execute the filters.
class FakeContext < ActionView::Base

  include Ubiquo::Helpers::CoreUbiquoHelpers

  attr_accessor :params

  def initialize
    params = {
      'controller' => 'tests',
      'action' => 'index'
    }
    @params = HashWithIndifferentAccess.new(params)
  end

  def url_for(options)
    "http://example.com/tests"
  end

end

# A helper model to be able to execute filters.
class FilterTestModel
  def self.create
    table = 'filter_tests'
    conn = ActiveRecord::Base.connection
    conn.drop_table(table) if conn.tables.include?(table)

    conn.create_table table.to_sym do |t|
      t.string   :title
      t.text     :description
      t.datetime :published_at
      t.boolean  :status, :default => false
      t.timestamps
    end

    model = table.classify
    Object.const_set(model, Class.new(ActiveRecord::Base)) unless Object.const_defined? model
    model.constantize
  end

end

# Helper class to easy the filter testing.
class UbiquoFilterTestCase < ActionView::TestCase

  include Ubiquo::Extensions::FilterHelpers

  def initialize(*args)
    ActionController::Routing::Routes.draw { |map| map.resources :tests }
    @model = FilterTestModel.create
    load_test_data
    @context = FakeContext.new
    super(*args)
  end

  def load_test_data
    [
     { :title => 'Yesterday loot was cool',
       :description => 'òuch réally?',
       :published_at => Date.today,
       :status => true
     },
     { :title => 'Today is the new yesterday. NIÑA',
       :description => 'bah loot',
       :published_at => Date.today,
       :status => false
     },
     { :title => 'Tíred',
       :description => 'stop',
       :published_at => Date.tomorrow,
       :status => false
     }
    ].each { |attrs| @model.create(attrs) }
  end

end

class FilterHelpersTest < UbiquoFilterTestCase

  attr_accessor :params

  def setup
    self.params = { :controller => 'tests', :action => 'index', 'filter_status' => '0' }
    @filter_set = filters_for 'FilterTest' do |f|
      f.boolean :status
    end
    @filters = @filter_set.filters
  end

  test "Should raise with invalid filters" do
    assert_raise UnknownFilter do
      filters_for 'FilterTest' do |f|
        f.wrong :invalid
      end
    end
  end

  test "Should raise if filters aren't defined" do
    assert_raise MissingFilterSetDefinition do
      @filter_set = nil
      send(:show_filters)
    end
  end

  test "Should be able to define a filter set" do
    assert_instance_of BooleanFilter, @filters.first
  end

  test "Should be able to render filters" do
    assert_respond_to self, :show_filters
    doc = HTML::Document.new(show_filters).root
    assert_select doc, "div#links_filter_content", 1
  end

  test "Should be able to display filter messages" do
    assert_respond_to self, :show_filter_info
    doc = HTML::Document.new(show_filter_info).root
    assert_select doc, "p[class=search_info]", 1
  end

end
