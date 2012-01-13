class UbiquoListSetting < UbiquoSetting

  serialize :value, Array

  def self.check_values values
    values.nil? || values.class == Array
  end

  # Check if the value is included in the alloweds
  def value_acceptable?
    self.allowed_values.blank? ||
    self.value.blank? ||
    !self.value.find { |v|
      !self.allowed_values.include?(v) &&
      !self.allowed_values.map(&:to_s).include?(v)
    }
  end

end
