module Ubiquo
  module Adapters
    module Sqlite
      def self.included(klass)
        klass.send :include, InstanceMethods
      end
      module InstanceMethods
        
        # Creates a sequence with name "name". Drops it before if it exists
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
        
        # Reset a sequence so that it will return the specified value as the next one
        # If next_value is not specified, the sequence will be reset to the "most appropiate value",
        # considering the values of existing records using this sequence
        def reset_sequence_value(name, next_value = nil)
          create_sequence(name)
          unless next_value
            table, field = name.split('_$_')
            next_value = self.execute('SELECT MAX(%s) as max FROM %s' % [field, table]).first['max'].to_i + 1
          end
          self.execute("INSERT INTO %s_sequence VALUES(%s);" % [name, (next_value || 1) - 1])
        end
      end
    end
  end
end
