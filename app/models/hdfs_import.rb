class HdfsImport < ActiveRecord::Base

  attr_accessible :hdfs_entry, :upload, :file_name

  belongs_to :user
  belongs_to :hdfs_entry
  belongs_to :upload, :dependent => :destroy

  validates_presence_of :user, :hdfs_entry, :upload
  validate :hdfs_entry_is_directory

  def destination_file_name
    file_name.present? ? file_name : upload.contents_file_name
  end

  private

  def hdfs_entry_is_directory
    errors.add(:hdfs_entry, :DIRECTORY_REQUIRED) unless hdfs_entry && hdfs_entry.is_directory?
  end

end
