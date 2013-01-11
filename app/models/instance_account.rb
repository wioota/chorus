class InstanceAccount < ActiveRecord::Base
  attr_accessible :db_username, :db_password, :owner
  validate :credentials_are_valid
  validates_presence_of :db_username, :db_password, :instance, :owner
  validates_uniqueness_of :owner_id, :scope => :instance_id

  attr_encrypted :db_password, :encryptor => ChorusEncryptor, :encrypt_method => :encrypt_password, :decrypt_method => :decrypt_password, :encode => false

  belongs_to :owner, :class_name => 'User'
  belongs_to :instance, :class_name => 'DataSource'
  has_and_belongs_to_many :gpdb_databases
  after_create :reindex_gpdb_instance
  after_destroy :reindex_gpdb_instance

  def reindex_gpdb_instance
    instance.refresh_databases_later unless instance.created_at > 1.minute.ago
  end

  private

  def credentials_are_valid
    association = association(:instance)
    if association.loaded?
      association.loaded! if association.stale_target?
    end
    return unless instance
    unless instance.valid_db_credentials?(self)
      errors.add(:base, :INVALID_PASSWORD)
    end
  end
end
