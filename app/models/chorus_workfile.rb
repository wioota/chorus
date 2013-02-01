class ChorusWorkfile < Workfile
  attr_accessible :versions_attributes, :as => [:default, :create]
  attr_accessible :svg_data, :execution_schema, :as => [:create]

  belongs_to :execution_schema, :class_name => 'GpdbSchema'

  has_many :versions, :foreign_key => :workfile_id, :class_name => 'WorkfileVersion', :order => 'version_num DESC', :inverse_of => :workfile
  has_many :drafts, :class_name => 'WorkfileDraft', :foreign_key => :workfile_id

  validates_format_of :file_name, :with => /^[a-zA-Z0-9_ \.\(\)\-]+$/

  before_validation :ensure_version_exists, :on => :create, :prepend => true
  before_create :set_execution_schema

  accepts_nested_attributes_for :versions

  def svg_data=(svg_data)
    transcoder = SvgToPng.new(svg_data)
    versions.build :contents => transcoder.fake_uploaded_file(file_name)
  end

  def build_new_version(user, source_file, message)
    versions.build(
        :owner => user,
        :modifier => user,
        :contents => source_file,
        :version_num => last_version_number + 1,
        :commit_message => message,
    )
  end

  def has_draft(current_user)
    !!WorkfileDraft.find_by_owner_id_and_workfile_id(current_user.id, id)
  end

  def entity_type_name
    'workfile'
  end

  private
  def last_version_number
    latest_workfile_version.try(:version_num) || 0
  end

  def init_file_name
    self.file_name ||= versions.first.file_name
    super
  end

  def set_execution_schema
    self.execution_schema = workspace.sandbox if versions.first && versions.first.sql? && !execution_schema
  end

  def ensure_version_exists
    version = versions.first
    unless(version)
      version = versions.build
      file = FakeFileUpload.new
      file.original_filename = file_name
      version.contents = file
    end
    version.owner = owner
    version.modifier = owner
    true
  end

end