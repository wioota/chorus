class Workfile < ActiveRecord::Base
  include SoftDelete

  attr_accessible :description, :file_name

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

  delegate :member_ids, :public, :to => :workspace

  attr_accessor :highlighted_attributes, :search_result_notes
  searchable do
    text :file_name, :stored => true, :boost => SOLR_PRIMARY_FIELD_BOOST
    text :description, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    integer :workspace_id, :multiple => true
    integer :member_ids, :multiple => true
    boolean :public
    string :grouping_id
    string :type_name
    string :security_type_name, :multiple => true
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

  acts_as_taggable

  def validate_name_uniqueness
    exists = Workfile.exists?(:file_name => file_name, :workspace_id => workspace.id)
    if exists
      errors.add(:file_name, "is not unique.")
      false
    else
      true
    end
  end

  def entity_type
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
  end
end
