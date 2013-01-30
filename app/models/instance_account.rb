class InstanceAccount < ActiveRecord::Base
  attr_accessible :db_username, :db_password, :owner
  validates_presence_of :db_username, :db_password, :gpdb_instance, :owner

  attr_encrypted :db_password, :encryptor => ChorusEncryptor, :encrypt_method => :encrypt_password, :decrypt_method => :decrypt_password, :encode => false

  belongs_to :owner, :class_name => 'User'
  belongs_to :gpdb_instance
  has_and_belongs_to_many :gpdb_databases
  after_save :reindex_gpdb_instance
  after_destroy :reindex_gpdb_instance
  after_destroy { gpdb_databases.clear }

  def reindex_gpdb_instance
    gpdb_instance.refresh_databases_later
  end
end
