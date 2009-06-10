module Ubiquo
  module Adapters
    module Mysql
      def self.included(klass)
        klass.send :include, InstanceMethods
      end
      module InstanceMethods
        
        # Creates a sequence with name "name"
        def create_sequence(name)
          drop_sequence(name)
          self.execute("CREATE TABLE %s_sequence (id INTEGER PRIMARY KEY auto_increment);" % name)
        end
        
        # Drops a sequence with name "name" if exists 
        def drop_sequence(name)
          self.execute("DROP TABLE IF EXISTS %s_sequence;" % name)
        end
        
        # Returns an array containing a list of the existing sequences that start with the given string
        def list_sequences(starts_with)
          self.select_rows("SHOW TABLES LIKE '#{starts_with}%_sequence'").map { |result| result.first.gsub('_sequence', '') }
        end
        
        # Returns the next value for the sequence "name"
        def next_val_sequence(name)
          self.insert_sql("INSERT INTO %s_sequence VALUES(NULL);" % name)
        end
      end
    end
  end
end
