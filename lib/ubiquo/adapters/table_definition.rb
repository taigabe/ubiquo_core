module Ubiquo
  module Adapters
    module TableDefinition
      
      # Creates an integer and an associated sequence field
      def sequence(table_name, field_name)
        integer field_name, :null => false 
        ActiveRecord::Base.connection.create_sequence("%s_$_%s" % [table_name, field_name])
      end
    end
  end
end
