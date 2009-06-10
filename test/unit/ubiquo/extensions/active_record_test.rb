require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::Extensions::ActiveRecordTest < ActiveSupport::TestCase

  def test_should_have_a_paginate
    ActiveRecord::Base.paginate
    assert ActiveRecord::Base.methods.include?('paginate')
  end
  
  def test_should_have_an_ubiquo_paginate
    assert ActiveRecord::Base.methods.include?('ubiquo_paginate')
  end
    
end
