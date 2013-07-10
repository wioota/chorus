class HdfsDataset < Dataset
  alias_attribute :file_mask, :query
  attr_accessible :file_mask
  validates_presence_of :file_mask


  belongs_to :hdfs_data_source
  delegate :data_source, :connect_with, :connect_as, :to => :hdfs_data_source

  def self.assemble!(attributes, hdfs_data_source, workspace, user)
      dataset = HdfsDataset.new attributes
      dataset.hdfs_data_source = hdfs_data_source
      dataset.save!

      workspace.associate_datasets(user, [dataset])
      dataset
  end

  def self.source_class
    HdfsDataSource
  end

  def associable?
    true
  end

  def needs_schema?
    false
  end

  def accessible_to(user)
    true
  end

  def verify_in_source(user)
    true
  end
end