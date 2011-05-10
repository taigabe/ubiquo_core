class IntegerSetting < Setting

  serialize :value #, Integer
  validates_numericality_of :value, :only_integer => true, :allow_nil => true

  def self.check_values values
    values.each do |v|
      if !v.nil? &&
          v.class != Fixnum && v.class != Integer
        return false
      end
    end
    true
  end
  
  def value
   self[:value].to_i
  end
end
