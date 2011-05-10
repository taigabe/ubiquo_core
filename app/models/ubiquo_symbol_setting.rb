class UbiquoSymbolSetting < UbiquoSetting

  serialize :value, Symbol

  def self.check_values values
    values.each do |v|
      if !v.nil? &&
          v.class != Symbol
        return false
      end
    end
    true
  end
end
