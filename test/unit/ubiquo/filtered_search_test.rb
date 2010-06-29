# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper.rb"

class FilteredSearchTest < ActiveSupport::TestCase

  def setup
    load_test_data
    @m = SearchTestModel
  end

  test "Should be able to define a named_scope and use it" do
    assert_nothing_raised do
      @m.class_eval do
        filtered_search_scopes :enable => [:desc]
        named_scope :desc, lambda { |v| { :conditions => "#{table_name}.description = '#{v}'"} }
      end
    end
    assert_equal [@m.find_by_description('stop')], @m.filtered_search({ 'filter_desc' => 'stop'})
  end

  test "Should not be able to use scopes without enabling them" do
    assert_raise Ubiquo::InvalidFilter do
      @m.class_eval do
        filtered_search_scopes
        named_scope :desc, lambda { |v| { :conditions => "#{table_name}.description = '#{v}'"} }
      end
      @m.filtered_search({'filter_desc' => 'Tired'})
    end
  end

  test "Should be able to use case and accent insensitive search" do
    assert_nothing_raised do
      @m.class_eval do
        filtered_search_scopes
      end
      assert_equal [@m.find_by_title('Tíred')], @m.filtered_search({'filter_text' => 'TIred'})
      assert_equal [@m.find_by_description('òuch réally?')], @m.filtered_search({'filter_text' => 'òuch réally?'})
      assert_equal [@m.find_by_description('bah loot')], @m.filtered_search({'filter_text' => 'niña'})
    end
  end

  test "Should be able to specify fields that should be affected by a text search" do
    @m.class_eval do
      filtered_search_scopes :text => [ :description ]
    end
    assert_equal [@m.find_by_description('bah loot')], @m.filtered_search({'filter_text' => 'loot'})
  end

  test "Should be able to restrict search to only specified scopes" do
    assert_raise Ubiquo::InvalidFilter do
      @m.class_eval do
        filtered_search_scopes
      end
      params = { 'filter_published_start' => Date.yesterday, 'filter_published_end' => (Date.tomorrow + 1), 'filter_text' => 'Tired' }
      @m.filtered_search(params, :scopes => [:text] )
    end
  end

  test "Should be able to use the locale scope" do
    # i18n plugin adds this scope and it should be usable by default.
    assert_nothing_raised do
      @m.class_eval do
        filtered_search_scopes

        named_scope :locale
      end
      @m.filtered_search({"filter_locale" => "es"})
    end
  end

  private

  def self.create_test_tables
    table = 'search_test_models'
    conn = ActiveRecord::Base.connection
    conn.drop_table(table) if conn.tables.include?(table)

    conn.create_table table.to_sym do |t|
      t.string :title
      t.string :description
      t.string :published_at
      t.boolean :private
    end

    model = 'SearchTestModel'
    Object.const_set(model, Class.new(ActiveRecord::Base)) unless Object.const_defined? model
  end

  def load_test_data
    [{ :title => 'Yesterday loot was cool',
       :description => 'òuch réally?',
       :published_at => Date.today,
       :private => true
     },
     { :title => 'Today is the new yesterday. NIÑA',
       :description => 'bah loot',
       :published_at => Date.today,
       :private => false
     },
     { :title => 'Tíred',
       :description => 'stop',
       :published_at => Date.tomorrow,
       :private => false
     }
    ].each { |attrs| SearchTestModel.create(attrs) }
  end

  create_test_tables

end
