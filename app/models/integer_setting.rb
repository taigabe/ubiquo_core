class IntegerSetting < Setting

  serialize :value #, Integer
  validates_numericality_of :value, :only_integer => true, :allow_nil => true

  def value
   self[:value].to_i
  end
end
