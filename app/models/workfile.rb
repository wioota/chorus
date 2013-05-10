class Workfile < ActiveRecord::Base
  include SoftDelete
  include TaggableBehavior
  include Notable

  @@entity_subtypes = Hash.new('ChorusWorkfile').merge!({
     'alpine' => 'AlpineWorkfile'
  })

  attr_accessible :description, :file_name, :as => [:default, :create]
  attr_accessible :owner, :workspace, :as => :create

  serialize :additional_data, JsonHashSerializer

  belongs_to :workspace
  belongs_to :owner, :class_name => 'User'

  has_many :activities, :as => :entity
  has_many :events, :through => :activities
  has_many :comments, :through => :events
  has_many :most_recent_comments, :through => :events, :source => :comments, :class_name => "Comment", :order => "id DESC", :limit => 1
  has_many :versions, :class_name => 'WorkfileVersion'

  belongs_to :latest_workfile_version, :class_name => 'WorkfileVersion'

  validates :workspace, presence: true
  validates :owner, presence: true
  validates_presence_of :file_name

  before_validation :init_file_name, :on => :create

  after_create :create_workfile_created_event, :if => :current_user
  after_create :update_has_added_workfile_on_workspace

  delegate :member_ids, :public, :to => :workspace

  attr_accessor :highlighted_attributes, :search_result_notes
  searchable_model :name_for_sort => :file_name do
    text :file_name, :stored => true, :boost => SOLR_PRIMARY_FIELD_BOOST
    text :description, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    text :version_comments, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST do
      versions.map { |version| version.commit_message }
    end
    integer :workspace_id, :multiple => true
    integer :member_ids, :multiple => true
    boolean :public
  end

  def self.eager_load_associations
    [
        {
            :latest_workfile_version => [
                {
                    :workfile => [
                        :workspace,
                        :owner,
                        :tags,
                        {:most_recent_comments => :author},
                        {:most_recent_notes => :actor},
                        {
                            :execution_schema => {
                                :scoped_parent => :data_source
                            }
                        }
                    ]
                },
                :owner,
                :modifier
            ]
        }
    ]
  end

  def self.build_for(params)
    klass = @@entity_subtypes[params[:entity_subtype]].constantize
    workfile = klass.new(params, :as => :create)
  end

  def self.with_file_type(file_type)
    where(content_type: file_type.downcase)
  end

  def self.order_by(column_name)
    if column_name.blank? || column_name == "file_name"
      order("lower(file_name)")
    else
      order("updated_at")
    end
  end


  def self.type_name
    'Workfile'
  end

  def self.add_search_permissions(current_user, search)
    unless current_user.admin?
      search.build do
        any_of do
          without :security_type_name, Workfile.security_type_name
          with :member_ids, current_user.id
          with :public, true
        end
      end
    end
  end

  def validate_name_uniqueness
    exists = Workfile.exists?(:file_name => file_name, :workspace_id => workspace.id)
    if exists
      errors.add(:file_name, "is not unique.")
      false
    else
      true
    end
  end

  def entity_type_name
    'workfile'
  end

  def copy(user, workspace)
    workfile = self.class.new
    workfile.file_name = file_name
    workfile.description = description
    workfile.workspace = workspace
    workfile.owner = user
    workfile.additional_data = additional_data

    workfile
  end

  private

  def init_file_name
    WorkfileName.resolve_name_for!(self)
    true
  end

  def create_workfile_created_event
    Events::WorkfileCreated.by(current_user).add(
        :workfile => self,
        :workspace => workspace,
        :commit_message => description
    )
  end

  def update_has_added_workfile_on_workspace
    workspace.has_added_workfile = true
    workspace.save!
  end

end
