class UbiquoPasswordSetting < UbiquoStringSetting

  serialize :value, String

  attr_accessor :confirmation
  
  validate :check_confirmation
  
  def check_confirmation
    self.errors.add :value, "The password and the confirmation do not match" if !confirmation_match?
  end
  
  def confirmation_match?    
    confirmation == value
  end
  
  def confirmation_key
    "confirmation_#{self.key}".to_sym
  end
  
  def handle_confirmation data
    self.confirmation = data.find{|k,v| k.to_sym == confirmation_key}.last.first.last rescue nil
  end

  def self.check_values values
    values.each do |v|
      if !v.nil? &&
          v.class != String
        return false
      end
    end
    true
  end
end
