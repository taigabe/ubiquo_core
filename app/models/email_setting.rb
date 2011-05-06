class EmailSetting < Setting
# es podra espeficar n llistat separat per comes, sempre, mai un de sol
  serialize :value, String
  validates_format_of :value, :with => /^.+@.+\..+$/, :allow_nil => true

end
