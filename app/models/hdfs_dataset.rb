class HdfsDataset < Dataset
  alias_attribute :file_mask, :query
  attr_accessible :file_mask
  validates_presence_of :file_mask
  validate :ensure_active_workspace, :on => :update, :if => Proc.new { |f| f.changed? }

  belongs_to :hdfs_data_source
  delegate :data_source, :connect_with, :connect_as, :to => :hdfs_data_source

  HdfsContentsError = Class.new(StandardError)

  def self.assemble!(attributes, hdfs_data_source, workspace, user)
      dataset = HdfsDataset.new attributes
      dataset.hdfs_data_source = hdfs_data_source
      dataset.save!

      workspace.associate_datasets(user, [dataset])
      dataset
  end

  def contents
    hdfs_query = Hdfs::QueryService.new(hdfs_data_source.host, hdfs_data_source.port, hdfs_data_source.username, hdfs_data_source.version)
    hdfs_query.show(file_mask)
  rescue StandardError => e
    raise HdfsContentsError.new(e)
  end

  def self.source_class
    HdfsDataSource
  end

  def in_workspace?(workspace)
    bound_workspaces.include?(workspace)
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

  def execution_location
    hdfs_data_source
  end

  def ensure_active_workspace
    any_archived = bound_workspaces.find { |workspace| workspace.archived? }
    self.errors[:dataset] << :ARCHIVED if any_archived
  end
end