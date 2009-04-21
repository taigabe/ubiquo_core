module Ubiquo
  module Adapters
    module Postgres
      def self.included(klass)
        klass.send :include, InstanceMethods
      end
      module InstanceMethods
        def create_sequence(name)
          drop_sequence(name)
          self.execute("CREATE SEQUENCE %s;" % name)
        end
        
        def drop_sequence(name)
          self.execute("DROP SEQUENCE IF EXISTS %s;" % name)
        end
        
        def list_sequences(starts_with)
          self.execute("SELECT c.relname AS sequencename FROM pg_class c WHERE (c.relkind = 'S' and c.relname ILIKE E'#{starts_with}%');").rows.flatten
        end
        
        def next_val_sequence(name)
          self.execute("SELECT nextval('%s');" % name).rows.first.first.to_i
        end
      end
    end
  end
end
