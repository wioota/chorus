class ChorusWorkfile < Workfile
  attr_accessible :versions_attributes

  belongs_to :execution_schema, :class_name => 'GpdbSchema'

  has_many :versions, :foreign_key => :workfile_id, :class_name => 'WorkfileVersion', :order => 'version_num DESC'
  has_many :drafts, :class_name => 'WorkfileDraft', :foreign_key => :workfile_id

  belongs_to :latest_workfile_version, :class_name => 'WorkfileVersion'

  validates_format_of :file_name, :with => /^[a-zA-Z0-9_ \.\(\)\-]+$/

  accepts_nested_attributes_for :versions

  def self.create_from_svg(attributes, workspace, owner)
    transcoder = SvgToPng.new(attributes[:svg_data])
    workfile = new(:versions_attributes => [{:contents => transcoder.fake_uploaded_file(attributes[:file_name]), :owner => owner, :modifier => owner}])
    workfile.owner = owner
    workfile.workspace = workspace
    workfile.save!
    workfile.reload
  end

  def self.create_from_file_upload(attributes, workspace, owner)
    workfile = new(attributes)
    workfile.owner = owner
    workfile.workspace = workspace

    if attributes[:execution_schema]
      workfile.execution_schema = GpdbSchema.find(attributes[:execution_schema][:id])
    else
      workfile.execution_schema = workspace.sandbox
    end

    raise ActiveRecord::RecordInvalid.new(workfile) if workfile.invalid?

    version = nil
    if(workfile.versions.first)
      version = workfile.versions.first
    else
      version = workfile.versions.build
      filename = workfile.file_name
      version.contents = File.new(File.join('/tmp/',filename), 'w')
    end

    version.owner = owner
    version.modifier = owner

    workfile.save!

    workfile.reload
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

end