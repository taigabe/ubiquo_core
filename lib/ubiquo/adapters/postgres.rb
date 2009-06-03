module Ubiquo
  module Adapters
    module Postgres
      def self.included(klass)
        klass.send :include, InstanceMethods
      end
      module InstanceMethods
        
        # Creates a sequence with name "name"
        def create_sequence(name)
          drop_sequence(name)
          self.execute("CREATE SEQUENCE %s;" % name)
        end
        
        # Drops a sequence with name "name" if exists 
        def drop_sequence(name)
          if(list_sequences("").include?(name.to_s))
            self.execute("DROP SEQUENCE %s;" % name)
          end
        end
        
        # Returns an array containing a list of the existing sequences that start with the given string
        def list_sequences(starts_with)
          self.execute("SELECT c.relname AS sequencename FROM pg_class c WHERE (c.relkind = 'S' and c.relname ILIKE E'#{starts_with}%');").entries.map { |result| result['sequencename'] }
        end
        
        # Returns the next value for the sequence "name"
        def next_val_sequence(name)
          self.execute("SELECT nextval('%s');" % name).entries.first['nextval'].to_i
        end
      end
    end
  end
end
