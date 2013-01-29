class Search
  include ActiveModel::Validations
  include ChorusApiValidationFormat
  attr_accessor :query, :page, :per_page, :workspace_id, :search_type, :is_tag
  attr_reader :models_to_search, :per_type, :current_user

  validate :valid_entity_type

  def initialize(current_user, params = {})
    @current_user = current_user
    @models_to_search = [User, GpdbDataSource, HadoopInstance, GnipInstance, Workspace, Workfile, Dataset, HdfsEntry, Attachment] unless @models_to_search.present?
    self.query = params[:query]
    self.per_type = params[:per_type]
    self.workspace_id = params[:workspace_id]
    self.search_type = params[:search_type]
    self.is_tag = params[:tag].to_s == 'true'
    if per_type
      self.per_page = 100
    else
      self.page = params[:page] || 1
      self.per_page = params[:per_page] || 50
    end
    self.entity_type = params[:entity_type]
  end

  def models_with_tags
    @models_to_search.select &:taggable?
  end

  def search
    @search ||= begin
      raise ApiValidationError.new(errors) unless valid?
      return if is_tag

      begin
        search = build_search
        search.execute
        search
      #rescue => e
      #  raise SunspotError.new(e.message)
      end
    end
  end

  def models
    @models ||= begin
      models = Hash.new() { |hsh, key| hsh[key] = [] }

      if is_tag
        models_with_tags.each do |model_class|
          results = model_class.tagged_with(query).paginate(:page => self.page, :per_page => self.per_page)
          results.each do |result|
            save_model(models, model_class.name, result)
          end
        end
      else
        search.associate_grouped_notes_with_primary_records

        search.results.each do |result|
          save_model(models, result.type_name, result)
        end

        populate_missing_records models
      end

      models[:this_workspace] = workspace_specific_results.results if workspace_specific_results
      models
    end
  end

  def save_model(models, class_name, model)
    model_key = class_name_to_key(class_name)
    models[model_key] << model unless per_type && models[model_key].length >= per_type
  end

  def users
    models[:users]
  end

  def instances
    models[:instances]
  end

  def workspaces
    models[:workspaces]
  end

  def workfiles
    models[:workfiles]
  end

  def datasets
    models[:datasets]
  end

  def hdfs_entries
    models[:hdfs_entries]
  end

  def attachments
    models[:attachments]
  end

  def this_workspace
    models[:this_workspace]
  end

  def num_found
    @num_found ||= begin
      num_found = Hash.new(0)
      if is_tag
        models_with_tags.each do |model_class|
          model_key = class_name_to_key(model_class.name)
          num_found[model_key] = model_class.tagged_with(query).count
        end
      else
        if count_using_facets?
          search.facet(:type_name).rows.each do |facet|
            num_found[class_name_to_key(facet.value)] = facet.count
          end
        else
          num_found[class_name_to_key(models_to_search.first.type_name)] = search.group(:grouping_id).total
        end
      end

      num_found[:this_workspace] = workspace_specific_results.num_found if workspace_specific_results
      num_found
    end
  end

  def per_type=(new_type)
    new_type_as_int = new_type.to_i
    if new_type_as_int > 0
      @per_type = new_type_as_int
    end
  end

  def entity_type=(new_type)
    return unless new_type
    @entity_type_set = true
    models_to_search.select! do |model|
      class_name_to_key(model.type_name) == class_name_to_key(new_type)
    end
  end

  def workspace
    @_workspace ||= Workspace.find(workspace_id)
  end

  private

  def count_using_facets?
    type_names_to_search.length > 1
  end

  def class_name_to_key(name)
    name.to_s.underscore.pluralize.to_sym
  end

  def populate_missing_records(models)
    return unless per_type

    type_names_to_search.each do |type_name|
      model_key = class_name_to_key(type_name)
      found_count = models[model_key].length
      if found_count < per_type && found_count < num_found[model_key]
        model_search = Search.new(current_user, :query => query, :per_page => per_type, :entity_type => type_name)
        models[model_key] = model_search.models[model_key]
      end
    end
  end

  def type_names_to_search
    models_to_search.map(&:type_name).uniq
  end

  def workspace_specific_results
    return unless workspace_id.present?
    @workspace_specific_results ||= begin
      type_name = type_names_to_search.first
      options = { :workspace_id => workspace_id, :per_page => per_type, :query => query }
      options.merge!({:entity_type => type_name}) if @entity_type_set
      WorkspaceSearch.new(current_user, options)
    end
  end

  def valid_entity_type
    errors.add(:entity_type, :invalid_entity_type) if models_to_search.blank?
  end

  private

  def build_search
    search = Sunspot.new_search(*(models_to_search + [Events::Note, Comment])) do
      group :grouping_id do
        limit 3
        truncate
      end
      fulltext query do
        highlight :max_snippets => 100
      end
      paginate :page => page, :per_page => per_page

      if count_using_facets?
        facet :type_name
      end

      with :type_name, type_names_to_search
    end
    models_to_search.each do |model_to_search|
      model_to_search.add_search_permissions(current_user, search) if model_to_search.respond_to? :add_search_permissions
    end
    search
  end
end