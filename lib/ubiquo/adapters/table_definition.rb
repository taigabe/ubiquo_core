module UbiquoVersions
  module Adapters
    module TableDefinition
      def content_id(table_name)
        integer :content_id, :null => false 
        ActiveRecord::Base.connection.create_sequence("%s_content_id" % table_name)
      end
    end
  end
end
