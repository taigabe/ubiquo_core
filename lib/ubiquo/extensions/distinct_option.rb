module Ubiquo
  module Extensions
    # As of Rails 3.2, an ActiveRecord::Relation#uniq exists that does what
    # ubiquo's :distinct option previously did. But looks like it's not working
    # correctly for calculations (some tests from distinct_option_test were failing),
    # so we leave the :distinct option here until that's fixed.
    # There is also an issue with Postgres select/order clauses, fixed here.
    # Once uniq works as expected, :distinct support can be removed.
    module DistinctOption

      def self.included klass
        klass.class_eval do
          klass::VALID_FIND_OPTIONS << :distinct
          alias_method_chain :apply_finder_options, :distinct
          attr_accessor :using_distinct
        end
        ::ActiveRecord::Calculations.class_eval do
          include Calculations
          alias_method_chain :calculate, :distinct
        end
      end

      # Applies the :distinct option when constructing sql queries
      def apply_finder_options_with_distinct(options)
        if options[:distinct]
          options_with_distinct = options.merge(:select => select_distinct(options))
          self.using_distinct = true
        end
        apply_finder_options_without_distinct(options_with_distinct || options)
      end

      module Calculations
      # Applies the :distinct option when constructing COUNT sql queries
      def calculate_with_distinct(operation, column_name, options = {})
        if using_distinct
          # column_name must be fixed since Rails default behaviour is not correct
          column_name = [connection.quote_table_name(table_name), primary_key] * '.'
          options_with_distinct = options.merge(:distinct => true)
        end
        calculate_without_distinct(operation, column_name, options_with_distinct || options)
      end
      end

      # Creates a valid SELECT DISTINCT clause,
      # that in Postgres takes into account the content in options[:order]
      def select_distinct(options)
        select_in_scope_attributes = select_values.join if select_values.present?
        rails_select = options[:select] || select_in_scope_attributes || default_select

        if connection.adapter_name == 'PostgreSQL'
          # By default table.id is the distinct on clause.
          # The +order_fields+ (["table1.field1", "table2.field2"])
          # should be inside the distinct on clause, else postgres will fail.
          order_fields = get_order_fields(options)
          distinct_fields = (Array(order_fields) << "#{table_name}.#{primary_key}").compact
          # Also postgres has the ON connector
          "DISTINCT ON (#{distinct_fields.join(',')}) #{rails_select}"
        else
          "DISTINCT (#{table_name}.#{primary_key}), #{rails_select}"
        end
      end

      # Returns the default content of a select clause
      def default_select
        quoted_table_name + '.*'
      end

      # Given an +options+ hash with an :order key,
      # returns the model fields that are being used to order.
      def get_order_fields(options)
        if order = options[:order]
          # general case: order is "table1.field1 asc, table2.field2 DESC"
          orders = order.split(',').map{|ord| ord.split(' ')}

          # now +orders+ is [["table1.field1", "asc"], ["table2.field2", "DESC"]]
          order_fields = orders.map{|order_part| order_part.first}
        end
      end

    end
  end
end
