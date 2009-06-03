module Ubiquo
  module Adapters
    module Sqlite
      def self.included(klass)
        klass.send :include, InstanceMethods
      end
      module InstanceMethods
        
        # Creates a sequence with name "name"
        def create_sequence(name)
          drop_sequence(name)
          self.execute("CREATE TABLE %s_sequence (id INTEGER PRIMARY KEY);" % name)
        end
        
        # Drops a sequence with name "name" if exists 
        def drop_sequence(name)
          self.execute("DROP TABLE IF EXISTS %s_sequence;" % name)
        end
        
        # Returns an array containing a list of the existing sequences that start with the given string
        def list_sequences(starts_with)
          self.execute("SELECT name FROM sqlite_master WHERE type = 'table' AND NOT name = 'sqlite_sequence' AND name LIKE '#{starts_with}%'").map { |result| result['name'].gsub('_sequence', '') }
        end
        
        # Returns the next value for the sequence "name"
        def next_val_sequence(name)
          self.insert_sql("INSERT INTO %s_sequence VALUES(NULL);" % name)
        end
      end
    end
  end
end
