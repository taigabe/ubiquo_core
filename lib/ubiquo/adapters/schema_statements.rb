module Ubiquo
  module Adapters
    module SchemaStatements
      def self.included(klass)
        klass.send(:alias_method_chain, :drop_table, :sequences)
      end
      def drop_table_with_sequences(table_name, options={})
        drop_table_without_sequences(table_name, options)
        ActiveRecord::Base.connection.list_sequences(table_name.to_s + "_").each do |sequence|
          unless sequence =~ /id_seq/
            ActiveRecord::Base.connection.drop_sequence sequence
          end
        end
      end
    end
  end
end
