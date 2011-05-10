class Setting < ActiveRecord::Base

  serialize :value
  serialize :options
  serialize :allowed_values
  validates_presence_of :context
  validates_presence_of :type
  # don't work as expected, probably because of the getters
  #validates_uniqueness_of :key, :scope => [:context]
  validate :override_enabled?
  validate :check_is_editable
  validate :check_config_existence
  validate :check_config_value_same
  validate :check_config_acceptance
  validate :check_config_value_acceptance

 #before_validation :try_setting_type
  before_validation :set_default_context
  before_validation :stringify_fields

  after_save :apply
  after_destroy :push_config

  # Check if the value is included in the alloweds
  def value_acceptable?
    self.allowed_values.blank? ||
      self.allowed_values.include?(self.value)
  end
  
  # Check if the context of the setting exists
  def context_exists?
    Ubiquo::Settings.context_exists?(self.context)
  end

  # Check is a setting is allowed to have a nil value
  def nullabe?
    context_exists? &&
    config_exists? &&
    Ubiquo::Settings[self.context].nullable?(self.key)
  end

  # Check if a setting exists
  def config_exists?
    context_exists? &&
    Ubiquo::Settings[self.context].option_exists?(self.key).present?
  end

  def config_editable?
    config_exists? &&
    Ubiquo::Settings[self.context].editable?(self.key).present?
  end
  
  def config_value_same?
    uhook_config_value_same?
  end

  def check_config_acceptance
    self.errors.add :value, 'value is not included in the alloweds' if !value_acceptable?
  end
  
  def check_config_value_same
    self.errors.add :value, 'cannot override a value with the same' if config_value_same?
  end

  def check_config_value_acceptance
    if self.class.respond_to?(:check_values) &&
        !self.class.check_values(Array(self.value))
      self.errors.add :value, "#{self.value} is not allowed"
    end
  end

  # Validate a setting
  def check_config_existence
    self.errors.add :value, 'not nullable' if  self.value.nil?  && !nullabe?
    self.errors.add :key, 'invented setting FTW!' if !config_exists?
    self.errors.add :context, 'invited context' if !context_exists?
  end

  def override_enabled?
    self.class.override_enabled?
  end
  
  # Check if overriden settings are enabled
  def self.override_enabled?
    Ubiquo::Settings.overridable?
  end

  # Tries to enable a specific setting 
  def apply 
    Ubiquo::Settings[self.context].add(self)
  end

  def self.find_or_build context, setting_key, options = {}
    uhook_find_or_build context.to_sym, setting_key.to_sym, options
  end

  def push_config
    self.class.push_config
  end
    
  # Tries to load and enable all overriden setting from db
  def self.push_config
    Ubiquo::Settings.load_from_backend!
  end

  def check_is_editable
    self.errors.add :key, 'not editable' if !self.config_editable?
  end

  # Validates uniqueness of the key
  def validate_key_uniqueness
    self.errors.add :key if Setting.find_by_context_and_key(self[:context], self[:key]).present?
  end

  # Set the defaul context for the setting
  def set_default_context
    self.context = Ubiquo::Settings.default_context if self.context.blank?
  end

  # Prepare context and key properties to storage as a string
  def stringify_fields
    self[:context] =  self[:context].to_s if self[:context].present?
    self[:key] = self[:key].to_s if self[:key].present?
  end
 
  # Accessor, format the key to a symbol
  def key
    self[:key].to_sym if self[:key].present?
  end

  # Accessor, format the context to a symbol
  def context
    self[:context].to_sym if self[:context].present?
  end

  def try_setting_type
    self.type = generate_type(self.context, self.key) if !self.type
    self.type = nil if self.type == Setting
  end

  def self.generate_type context, key
    value = Ubiquo::Settings[context.to_sym].get(key.to_sym, :any_value => true)
    return PasswordSetting if value.class == String && Ubiquo::Settings[context.to_sym].options(key.to_sym)[:is_password]
    return BooleanSetting if value == true || value == false
    return IntegerSetting if value.class == Fixnum
    "#{value.class}Setting".constantize rescue Setting
  end
  
  def generated_from_another_value?
    uhook_generated_from_another_value?
  end

#  def to_s
#   "#{key}:#{value}"
# end
end
