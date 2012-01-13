class UbiquoEmailSetting < UbiquoSetting
# es podra espeficar n llistat separat per comes, sempre, mai un de sol
  serialize :value, String
  validates_format_of :value, :with => /^.+@.+\..+$/, :allow_nil => true

  EMAIL_REGEX="^.+@.+\..+$"

  def self.check_values values
    values.each do |v|
      if !v.nil? &&
          (v.class != String || v !~ Regexp.new(EMAIL_REGEX) )
        return false
      end
    end
    true
  end

end
