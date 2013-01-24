require 'events/base'
require 'model_map'

module Events
  class Note < Base
    include SearchableHtml

    validates_presence_of :actor_id
    validate :no_note_on_archived_workspace, :on => :create

    searchable_html :body
    searchable do
      string :grouping_id
      string :type_name
      string :security_type_name, :multiple => true
    end

    attr_accessible :dataset_ids, :workfile_ids

    has_additional_data :body

    delegate :grouping_id, :type_name, :security_type_name, :to => :primary_target

    def self.create_on_model(model, params, creator)
      body = params[:body]
      workspace_id = params[:workspace_id]
      insight = params[:is_insight]

      if model.kind_of?(Dataset)
        entity_type = 'dataset'
      elsif model.kind_of?(Workfile)
        entity_type = 'workfile'
      elsif model.kind_of?(HdfsEntry)
        entity_type = 'hdfs_file'
      else
        entity_type = model.class.name.underscore
      end

      event_params = {
        entity_type => model,
        "body" => body,
        'dataset_ids' => params[:dataset_ids],
        'workfile_ids' => params[:workfile_ids],
        'insight' => insight
      }

      if insight
        event_params["promoted_by"] = creator
        event_params["promotion_time"] = Time.current
      end

      event_params["workspace"] = Workspace.find(workspace_id) if workspace_id
      event_class = event_class_for_model(model, workspace_id)
      event_class.by(creator).add(event_params)
    end

    def self.insights
      where(:insight => true)
    end

    def promote_to_insight(actor)
      self.insight = true
      self.promoted_by = actor
      touch(:promotion_time)
      save!
    end

    def set_insight_published(published)
      self.published = published
      save!
    end

    private

    def no_note_on_archived_workspace
      errors.add(:workspace, :generic, {:message => "Can not add a note on an archived workspace"}) if workspace.present? && workspace.archived?
    end

    class << self
      private

      def include_shared_search_fields(target_name)
        klass = ModelMap.class_from_type(target_name.to_s)
        define_shared_search_fields(klass.shared_search_fields, target_name)
      end

      def event_class_for_model(model, workspace_id)
        case model
          when GpdbDataSource
            Events::NoteOnGreenplumInstance
          when GnipInstance
            Events::NoteOnGnipInstance
          when HadoopInstance
            Events::NoteOnHadoopInstance
          when Workspace
            Events::NoteOnWorkspace
          when Workfile
            Events::NoteOnWorkfile
          when HdfsEntry
            Events::NoteOnHdfsFile
          when Dataset
            workspace_id ? Events::NoteOnWorkspaceDataset : Events::NoteOnDataset
          else
            raise StandardError, "Unknown model type #{model.class.name}"
        end
      end
    end
  end
end

# Preload all note classes, otherwise, attachment.note will not work in dev mode.
require 'events/note_on_dataset'
require 'events/note_on_greenplum_instance'
require 'events/note_on_gnip_instance'
require 'events/note_on_hadoop_instance'
require 'events/note_on_hdfs_file'
require 'events/note_on_workfile'
require 'events/note_on_workspace'
require 'events/note_on_workspace_dataset'
