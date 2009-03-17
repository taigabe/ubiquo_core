class Link < ActiveRecord::Base
  TARGET_OPTIONS = [[I18n.t('ubiquo.link_target_self'), "_self"], [I18n.t('ubiquo.link_target_blank'), "_blank"]]
  TARGETS = TARGET_OPTIONS.map { |name, key| key }
  validates_presence_of :title, :url
  validates_inclusion_of :target, :in => TARGETS 
  belongs_to :linkable, :polymorphic => true
  before_save :check_protocol
 
  private
  
  # If no protocol is set for the URL, set http by default 
  def check_protocol(default_protocol="http://")
    return if self.url =~ /^\w+:\/\// || self.url =~ /^\//
    self.url = default_protocol + self.url.to_s
  end

end
