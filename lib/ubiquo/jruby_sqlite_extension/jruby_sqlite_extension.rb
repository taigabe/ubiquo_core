module UbiquoExtensions
  module JrubySqliteExtension
    def self.extended klass
      klass.send :include, InstanceMethods
    end
    
    module InstanceMethods
      def create_function( name, arity, text_rep='test_var',#Constants::TextRep::ANY,
          &block ) # :yields: func, *args
        # begin
        SQLiteJDBCRubyFunction.create(self.connection, name, SQLiteJDBCRubyFunction.new)
        self
      end

      funct = org.sqlite.Function
      
      class SQLiteJDBCRubyFunction < funct
        def xFunc
          1
        end
      end
    end
  end
end
