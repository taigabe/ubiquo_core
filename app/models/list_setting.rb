class ListSetting < Setting

  serialize :value, Array

  def self.check_values values
    [values].each do |v|
      if !v.nil? &&
          v.class != Array
          return false
      end
    end
    true
  end
end
