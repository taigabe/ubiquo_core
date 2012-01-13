class UbiquoStringSetting < UbiquoSetting

  serialize :value, String
  before_validation :assign_blank_values_to_nil

  def text?
    self.options.present? && self.options[:is_text]
  end
  
  def assign_blank_values_to_nil
    self.value = nil if self.value.blank?
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
