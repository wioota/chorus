class InstanceAccount < ActiveRecord::Base
  attr_accessor :legacy_migrate

  attr_accessible :db_username, :db_password, :owner
  validate :credentials_are_valid, :unless => :legacy_migrate
  validates_presence_of :db_username, :db_password, :data_source, :owner
  validates_uniqueness_of :owner_id, :scope => :data_source_id

  attr_encrypted :db_password, :encryptor => ChorusEncryptor, :encrypt_method => :encrypt_password, :decrypt_method => :decrypt_password, :encode => false

  belongs_to :owner, :class_name => 'User'
  belongs_to :data_source
  has_and_belongs_to_many :gpdb_databases
  after_save :reindex_data_source
  after_destroy :reindex_data_source
  after_destroy { gpdb_databases.clear }

  def reindex_data_source
    data_source.refresh_databases_later
  end

  private

  def credentials_are_valid
    association = association(:data_source)
    if association.loaded?
      association.loaded! if association.stale_target?
    end
    return unless data_source && db_username.present? && db_password.present?
    unless data_source.valid_db_credentials?(self)
      errors.add(:base, :INVALID_PASSWORD)
    end
  end
end
