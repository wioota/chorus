class Session < ActiveRecord::Base
  attr_accessor :username, :password
  attr_accessible :username, :password

  belongs_to :user

  validates_presence_of :username, :password
  validate :credentials_are_valid

  before_create :generate_session_id

  def expired?
    updated_at < ChorusConfig.instance['session_timeout_minutes'].minutes.ago
  end

  def update_expiration!
    touch if updated_at < 5.minutes.ago
  end

  private

  def credentials_are_valid
    return if errors.present?
    if LdapClient.enabled? && !(username =~ /^(chorus|edc)admin$/)
      authenticated = LdapClient.authenticate(username, password)
      self.user = User.find_by_username(username) if authenticated
    else
      self.user = User.authenticate(username, password)
    end

    errors.add(:username_or_password, :invalid) unless user
  end

  def generate_session_id
    self.session_id = SecureRandom.hex(20)
  end
end