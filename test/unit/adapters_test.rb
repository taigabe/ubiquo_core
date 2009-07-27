require File.dirname(__FILE__) + "/../test_helper.rb"
require 'mocha'

class Ubiquo::AdaptersTest < ActiveSupport::TestCase
  def test_sequences
    ActiveRecord::Base.connection.create_sequence(:test)
    
    (1..10).each do |i|
      assert_equal i, ActiveRecord::Base.connection.next_val_sequence(:test)
    end
    
    ActiveRecord::Base.connection.drop_sequence(:test)
    assert_raises ActiveRecord::StatementInvalid do
      ActiveRecord::Base.connection.next_val_sequence(:test)
    end
  end
  
  def test_create_sequence
    ActiveRecord::Base.connection.expects(:create_sequence).with("test_$_content_id").once
    
    definition = nil
    ActiveRecord::Base.connection.create_table(:test, :force => true){|table|
      definition = table
      table.sequence :test, :content_id
    }
    ActiveRecord::Base.connection.drop_table(:test)
    assert_not_nil definition[:content_id]
  end
  
  def test_gets_sequences_list
    ActiveRecord::Base.connection.create_table(:test, :force => true){|table|
      table.sequence :test, :content_id
    }
    assert ActiveRecord::Base.connection.list_sequences("test_").include?('test_$_content_id')
    ActiveRecord::Base.connection.drop_table(:test)
  end
  
  def test_drop_created_sequences
    ActiveRecord::Base.connection.create_table(:test, :force => true){|table|
      table.sequence :test, :content_id
    }
    assert ActiveRecord::Base.connection.list_sequences("test_").include?('test_$_content_id')
    
    ActiveRecord::Base.connection.drop_table(:test)
    assert !ActiveRecord::Base.connection.list_sequences("test_").include?('test_$_content_id')
    
  end
  
  def test_reset_sequence_value
    ActiveRecord::Base.connection.create_table(:test, :force => true){|table|
      table.sequence :test, :content_id
    }
    
    ActiveRecord::Base.connection.reset_sequence_value('test_$_content_id', 5)
    assert_equal 5, ActiveRecord::Base.connection.next_val_sequence('test_$_content_id')
    
    ActiveRecord::Base.connection.reset_sequence_value('test_$_content_id')
    assert_equal 1, ActiveRecord::Base.connection.next_val_sequence('test_$_content_id')
    
    ActiveRecord::Base.connection.execute("INSERT INTO test (content_id) VALUES (10)")
    ActiveRecord::Base.connection.reset_sequence_value('test_$_content_id')
    assert_equal 11, ActiveRecord::Base.connection.next_val_sequence('test_$_content_id')
    
    ActiveRecord::Base.connection.drop_table(:test)
  end
  
  def test_should_exist_sequences_after_create
    ActiveRecord::Base.connection.create_table(:test, :force => true){|table|
      table.sequence :test, :content_id
    }
    assert ActiveRecord::Base.connection.list_sequences("test_").include?("test_$_content_id")
  end

  def test_should_same_create_table_options_that_drop_table_options
    options = { :force => true, :test => "test" }
    ActiveRecord::Base.connection.create_table(:test, options) { }
    ActiveRecord::Base.connection.expects(:drop_table).with(:test, options)
    ActiveRecord::Base.connection.expects(:execute).at_least_once
    ActiveRecord::Base.connection.create_table(:test, options) { }
  end

  def test_drop_table_doesnt_use_force_option
    options = stub
    options.expects("[]").with(:force).never
    ActiveRecord::Base.connection.create_table(:test, { :force => true }) { }
    ActiveRecord::Base.connection.drop_table(:test, options) { }
  end
  
end
