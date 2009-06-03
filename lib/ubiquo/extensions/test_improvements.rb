
require 'tempfile'
module Ubiquo
  module Extensions
    module TestImprovements
      
      def self.included(klass)
        klass.extend(ClassMethods)
        klass.send(:include, TestFile)
      end

      # Like assert_equal but test that expected and actual sets are equal
      def assert_equal_set(expected, actual, *args)
        assert_equal(expected.to_set, actual.to_set, *args)  
      end

      module TestFile
        
        private
        
        # Create a test file for tests
        def test_file(contents = "contents")
          f = Tempfile.new("test.txt")
          f.write contents
          f.flush
          f.close
          @test_file_path = f.path
          open(f.path)
        end
      end
      
      module ClassMethods
        # Loads the special set of ubiquo fixtures
        def use_ubiquo_fixtures
          fixture_set_path = File.join(RAILS_ROOT, "tmp", "ubiquo_fixtures")
          raise "Unable to find ubiquo fixtures [#{fixture_set_path}]" unless File.exists?(fixture_set_path)        
          fixture_files = Dir.entries(fixture_set_path).reject {|e| e =~ /^\./ || e !~ /\.yml$/}
          raise "No fixtures found in #{fixture_set_path}, have you run rake test:fixture_sets:scan?" if fixture_files.empty?
          @@original_fixture_path = ActiveSupport::TestCase.fixture_path        
          ActiveSupport::TestCase.fixture_path = fixture_set_path
          fixture_symbols = fixture_files.map {|f| f.gsub('.yml', '').to_sym}
          fixtures(*fixture_symbols)
        end
        
        def teardown_with_fixture_set
          ActiveSupport::TestCase.fixture_path = @@original_fixture_path
        end
        alias_method :teardown, :teardown_with_fixture_set
      end
    end
  end
end
