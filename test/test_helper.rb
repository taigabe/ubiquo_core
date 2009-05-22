require File.dirname(__FILE__) + "/../../../../test/test_helper.rb"

if ActiveRecord::Base.connection.class.to_s == "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
  conn.client_min_messages = "ERROR"
end
