class UbiquoBooleanSetting < UbiquoSetting 

  serialize :value
  validate :validate_boolean

  before_validation :parse_value
  
  def value
    ["1", 1, true, "true"].include?(self[:value]) ? true : false
  end

  def value= v
    self[:value] = v
    parse_value
    self[:value]
  end

  def self.check_values values
    values.each do |v|
      if !v.nil? && v != true && v != false
        return false
      end
    end
    true
  end

  def parse_value
    self[:value] = value
    true
  end

  protected
 
  def validate_boolean
    self.errors.add :value if self.value != true && self.value != false
    true
  end

end
