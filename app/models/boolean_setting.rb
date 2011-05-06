class BooleanSetting < Setting 

  serialize :value
  validate :validate_boolean

  before_validation :parse_value
  
  def value
    self[:value] == "true" ? true : false
  end  
  
  protected

  def parse_value
    self.value = ["1", 1, true, "true"].include?(self.value) ? true : false
    true
  end
  
  def validate_boolean
    self.errors.add :value if self.value != true && self.value != false
    true
  end

end
