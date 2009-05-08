require File.dirname(__FILE__) + "/../../../../test/test_helper.rb"

case conn = ActiveRecord::Base.connection
when ActiveRecord::ConnectionAdapters::AbstractAdapter
  conn.client_min_messages = "ERROR"
end
