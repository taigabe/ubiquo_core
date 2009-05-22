module Ubiquo
  module Adapters
    module Sqlite
      def self.included(klass)
        klass.send :include, InstanceMethods
      end
      module InstanceMethods
        def create_sequence(name)
          drop_sequence(name)
          self.execute("CREATE TABLE %s_sequence (id INTEGER PRIMARY KEY);" % name)
        end
        
        def drop_sequence(name)
          self.execute("DROP TABLE IF EXISTS %s_sequence;" % name)
        end
        
        def list_sequences(starts_with)          
          self.execute("SELECT name FROM sqlite_master WHERE type = 'table' AND NOT name = 'sqlite_sequence' AND name LIKE '#{starts_with}%'").map { |result| result['name'].gsub('_sequence', '') }
        end
        
        def next_val_sequence(name)
          self.insert_sql("INSERT INTO %s_sequence VALUES(NULL);" % name)
        end
      end
    end
  end
end
