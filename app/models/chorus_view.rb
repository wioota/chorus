require 'dataset'

class ChorusView < Dataset
  include SharedSearch

  attr_accessible :query, :object_name, :schema_id, :workspace_id
  attr_readonly :schema_id, :workspace_id

  belongs_to :workspace

  include_shared_search_fields :workspace, :workspace

  validates_presence_of :workspace, :query
  validate :validate_query, :if => :query

  alias_attribute :object_name, :name

  def create_duplicate_chorus_view name
    chorus_view = ChorusView.new
    chorus_view.schema = schema
    chorus_view.query = query
    chorus_view.master_table = master_table
    chorus_view.name = name
    chorus_view.workspace = workspace
    chorus_view
  end

  def validate_query
    return unless changes.include?(:query)
    unless query.upcase.start_with?("SELECT", "WITH")
      errors.add(:query, :start_with_keywords)
    end

    schema.connect_as(current_user).transaction(:rollback => :always) do |conn|
      begin
        conn.fetch(query).all
      rescue Sequel::DatabaseError => e
        case e.message
          when /Multiple ResultSets/
            errors.add(:query, :multiple_result_sets)
          else
            errors.add(:query, :generic, {:message => e.message})
        end
      end
    end
  end


  def preview_sql
    query
  end

  def column_name
  end

  def check_duplicate_column(user)
    account = gpdb_instance.account_for_user!(user)
    GpdbColumn.columns_for(account, self)
  end

  def query_setup_sql
    #set search_path to "#{schema.name}";
    %Q{create temp view "#{name}" as #{query};}
  end

  def as_sequel
    {
        :query => query_setup_sql,
        :identifier => Sequel.qualify(schema.name, name)
    }
  end

  def scoped_name
    %Q{"#{name}"}
  end

  def all_rows_sql(limit = nil)
    sql = "SELECT * FROM (#{query.gsub(';', '');}) AS cv_query"
    sql += " LIMIT #{limit}" if limit
    sql
  end

  def convert_to_database_view(name, user)
    view = schema.datasets.views.build(:name => name)
    view.query = query

    if schema.connect_as(user).view_exists?(name)
      view.errors.add(:name, :taken)
      raise ActiveRecord::RecordInvalid.new(view)
    end

    begin
      schema.connect_as(user).create_view(name, query)
      view.save!
      view
      # TODO
    rescue GreenplumConnection::DatabaseError => e
      view.errors.add(:base, :generic, {:message => e.message})
      raise ActiveRecord::RecordInvalid.new(view)
    end
  end

  def add_metadata!(account)
    metadata = nil
    with_gpdb_connection(account) do |connection|
      jdbc_conn = connection.raw_connection.connection
      s = jdbc_conn.prepareStatement(query)
      flag = org.postgresql.core::QueryExecutor::QUERY_DESCRIBE_ONLY
      s.executeWithFlags(flag)
      results = s.getResultSet
      metadata = results.getMetaData
    end
    @statistics = DatasetStatistics.new('column_count' => metadata.getColumnCount)
  end
end