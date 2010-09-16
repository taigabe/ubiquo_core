require File.dirname(__FILE__) + '/../test_helper'
require 'ubiquo/relation_selector'


class RelationSelectorTest < ActionView::TestCase

  include Ubiquo::RelationSelector::Helper

  def setup
    set_relations
  end
  
  test "should_create_right_selector" do
    #Select, checkboxes, autocomplete
    obj = TestOnlyModel.new
    
    r = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj,
      :type => :autocomplete)
    doc = HTML::Document.new(r)
    assert_select doc.root, 'script'
    
    r = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj,
      :type => :select)
    doc = HTML::Document.new(r)
    assert_select doc.root, 'select'
    
    r = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj,
      :type => :checkbox)
    doc = HTML::Document.new(r)
    assert_select doc.root, 'input'
    
  end
  
  test "should_display_owned_value" do
    #Display all options with the instance choice selected
    obj1 = TestOnlyModel.create(:name => 'first')
    obj2 = TestOnlyModelTwo.create(:name => 'second')
    obj3 = TestOnlyModelTwo.create(:name => 'third')
    
    obj1.test_only_model_twos << obj2
    
    r = relation_selector('test_only_model',
      :test_only_model_twos,
      :object => obj1,
      :type => :checkbox)
    
    doc = HTML::Document.new(r)
    assert_select doc.root, 'input[type=checkbox][checked=checked]', 1
    assert_select doc.root, 'input[type=hidden]', 1    
  end
  
  test "should_display_owned_values" do
    #Display all options with the instance choices selected
    obj1 = TestOnlyModel.create(:name => 'first')
    obj2 = TestOnlyModelTwo.create(:name => 'second')
    obj3 = TestOnlyModelTwo.create(:name  => 'third')
    obj4 = TestOnlyModelTwo.create(:name => 'fourth')

    obj1.test_only_model_twos << obj2
    obj1.test_only_model_twos << obj3
    
    
    r = relation_selector('test_only_model',
      :test_only_model_twos,
      :object => obj1,
      :type => :checkbox)
    
    doc = HTML::Document.new(r)
    assert_select doc.root, 'input[type=checkbox][checked=checked]', 2
    assert_select doc.root, 'input[type=hidden]', 1
    
  end
  
  test "should_use_desired_name" do
    obj1 = TestOnlyModel.create(:name => 'first')
    obj2 = TestOnlyModelTwo.create(:arbitrary_name => 'second', :name => 'no_name')
    obj3 = TestOnlyModelTwo.create(:arbitrary_name => 'third', :name => 'no_name')
    
    obj1.test_only_model_two = obj2
    obj1.save
    
    r = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj1,
      :name_field => 'arbitrary_name',
      :type => :select)

    doc = HTML::Document.new(r)
    assert_select doc.root, 'select' do |lk|
      assert_select lk.first, 'option' do |opt|
        opt.each do |s_opt|
          assert_equal obj2.arbitrary_name, s_opt.children.first.content if s_opt['selected'].present?
        end
      end
    end
  end

  test "should_use_additional_url_params" do
    obj1 = TestOnlyModel.create(:name => 'first')
    opts = {:param1 => 'is_one'}
    r = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj1,
      :url_params => opts,
      :type => :autocomplete)
    
    assert_equal (r.index(ubiquo_test_only_model_twos_url({:format => 'js'}.merge(opts)))).present?, true
    
  end
  
  test "should_display_required_field_if_needed" do
    obj1 = TestOnlyModel.create(:name => 'first')
    opts = {:param1 => 'is_one'}
    r1 = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj1,
      :required => true,
      :type => :select)
    assert_equal r1.index('<label>Test only model two *</label>').present?, true
    r2 = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj1,
      :type => :select)
    assert_equal r2.index('<label>Test only model two</label>').present?, true
    
  end
  
  test "additional_options_display_if_needed" do
    obj1 = TestOnlyModel.create(:name => 'first')
    opts = {:param1 => 'is_one'}
    r1 = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj1,
      :type => :select)
    assert_equal r1.index('relation_new').present?, true
    r2 = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj1,
      :hide_controls => true,
      :type => :select)
    assert_equal r2.index('relation_new').present?, false
  end

  private

  def new_ubiquo_test_only_model_url options = {}
    return url_former('a/fake/url', options)
  end

  def ubiquo_test_only_models_url options = {}
    return url_former('another/fake/url', options)
  end

  def new_ubiquo_test_only_model_two_url options = {}
    return url_former('another/one/fake/url', options)
  end

  def ubiquo_test_only_model_twos_url options = {}
    return url_former('yet/another/one/fake/url', options)
  end

  def url_former name, options = {}
    return "#{name}?#{options.map{|lk| "#{lk.first.to_s}=#{lk.last}"}.join('&')}"
  end
  
end

create_relation_test_model_backend
