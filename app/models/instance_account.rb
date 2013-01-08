class InstanceAccount < ActiveRecord::Base
  attr_accessible :db_username, :db_password, :owner
  validates_presence_of :db_username, :db_password, :instance, :owner

  attr_encrypted :db_password, :encryptor => ChorusEncryptor, :encrypt_method => :encrypt_password, :decrypt_method => :decrypt_password, :encode => false

  belongs_to :owner, :class_name => 'User'
  belongs_to :instance, :class_name => 'GpdbInstance'
  has_and_belongs_to_many :gpdb_databases
  after_create :reindex_gpdb_instance
  after_destroy :reindex_gpdb_instance

  def reindex_gpdb_instance
    instance.refresh_databases_later
  end
end
