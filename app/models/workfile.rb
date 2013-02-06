class Workfile < ActiveRecord::Base
  include SoftDelete

  @@entity_subtypes = Hash.new('ChorusWorkfile').merge!({
     'alpine' => 'AlpineWorkfile'
  })

  acts_as_taggable

  attr_accessible :description, :file_name, :as => [:default, :create]
  attr_accessible :owner, :workspace, :as => :create

  serialize :additional_data, JsonHashSerializer

  belongs_to :workspace
  belongs_to :owner, :class_name => 'User'

  has_many :activities, :as => :entity
  has_many :events, :through => :activities
  has_many :notes, :through => :activities, :source => :event, :class_name => "Events::Note"
  has_many :comments, :through => :events

  belongs_to :latest_workfile_version, :class_name => 'WorkfileVersion'

  validates_presence_of :file_name

  before_validation :init_file_name, :on => :create

  after_create :create_workfile_created_event, :if => :current_user
  after_create :update_has_added_workfile_on_workspace

  delegate :member_ids, :public, :to => :workspace

  attr_accessor :highlighted_attributes, :search_result_notes
  searchable_model :name_for_sort => :file_name do
    text :file_name, :stored => true, :boost => SOLR_PRIMARY_FIELD_BOOST
    text :description, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    integer :workspace_id, :multiple => true
    integer :member_ids, :multiple => true
    boolean :public
  end

  def self.build_for(params)
    klass = @@entity_subtypes[params[:entity_subtype]].constantize
    workfile = klass.new(params, :as => :create)
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
