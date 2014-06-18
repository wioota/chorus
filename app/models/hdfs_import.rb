class HdfsImport < ActiveRecord::Base

  attr_accessible :hdfs_entry, :upload

  belongs_to :user
  belongs_to :hdfs_entry
  belongs_to :upload

  validates_presence_of :user, :hdfs_entry, :upload
  validate :hdfs_entry_is_directory

  private

  def hdfs_entry_is_directory
    errors.add(:hdfs_entry, :DIRECTORY_REQUIRED) unless hdfs_entry && hdfs_entry.is_directory?
  end

end
