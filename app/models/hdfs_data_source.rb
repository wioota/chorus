class HdfsDataSource < ActiveRecord::Base
  include TaggableBehavior
  include Notable
  include SoftDelete
  include CommonDataSourceBehavior

  attr_accessible :name, :host, :port, :description, :username, :group_list
  belongs_to :owner, :class_name => 'User'
  has_many :activities, :as => :entity
  has_many :events, :through => :activities
  has_many :hdfs_entries
  validates_presence_of :name, :host, :port
  validates_length_of :name, :maximum => 64

  validates_with DataSourceNameValidator

  after_create :create_root_entry
  after_destroy :enqueue_destroy_entries

  def url
    "gphdfs://#{host}:#{port}/"
  end

  def self.refresh(id)
    find(id).refresh
  end

  def update_state_and_version
    self.state = Hdfs::QueryService.accessible?(self) ? "online" : "offline"
    self.version = Hdfs::QueryService.version_of(self) if online?
  end

  def refresh(path = "/")
    entries = HdfsEntry.list(path, self)
    entries.each { |entry| refresh(entry.path) if entry.is_directory? }
  rescue Hdfs::DirectoryNotFoundError => e
    return unless path == '/'
    hdfs_entries.each do |hdfs_entry|
      hdfs_entry.mark_stale!
    end
  end

  def create_root_entry
    hdfs_entries.create({:hdfs_data_source => self, :path => "/", :is_directory => true}, { :without_protection => true })
  end

  private

  def enqueue_destroy_entries
    QC.enqueue_if_not_queued("HdfsEntry.destroy_entries", id)
  end

end
