class DecimalSetting < Setting

  serialize :value, Float
  validates_numericality_of :value, :only_integer => false, :allow_nil => true


end
