module UbiquoExtensions
  autoload :JrubySqliteExtension, 'ubiquo/jruby_sqlite_extension/jruby_sqlite_extension'
end
::ActiveRecord::ConnectionAdapters::Sqlite3JdbcConnection.send(:extend, UbiquoExtensions::JrubySqliteExtension)
