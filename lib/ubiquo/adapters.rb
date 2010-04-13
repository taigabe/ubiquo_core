#
# Comment sqlite statements until we implement it completely
#

module Ubiquo
  module Adapters
    autoload :Postgres, "ubiquo/adapters/postgres"
    autoload :Sqlite, "ubiquo/adapters/sqlite"
    autoload :Mysql, "ubiquo/adapters/mysql"
    autoload :TableDefinition, "ubiquo/adapters/table_definition"
    autoload :SchemaStatements, "ubiquo/adapters/schema_statements"
  end
end
connection = begin
  ActiveRecord::Base.connection
rescue MissingSourceFile
  false
end
if connection
  
  included_module = case connection.class.to_s
    when "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
      Ubiquo::Adapters::Postgres
    when "ActiveRecord::ConnectionAdapters::SQLite3Adapter"
      Ubiquo::Adapters::Sqlite
    when "ActiveRecord::ConnectionAdapters::MysqlAdapter"
      Ubiquo::Adapters::Mysql
    else
      nil
  end

  included_module ||= case connection.config[:adapter]
    when "jdbcmysql"
      Ubiquo::Adapters::Mysql
    when "jdbcpostgresql"
      Ubiquo::Adapters::Postgres
    when "jdbcsqlite3"
      Ubiquo::Adapters::Sqlite
    else nil
  end rescue nil


  raise "Only PostgreSQL, MySQL and SQLite supported" if  included_module == nil
  
  ActiveRecord::Base.connection.class.send(:include, included_module)
  ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, Ubiquo::Adapters::TableDefinition)
  ActiveRecord::ConnectionAdapters::SchemaStatements.send(:include, Ubiquo::Adapters::SchemaStatements)
end
