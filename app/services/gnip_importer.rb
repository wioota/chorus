class GnipException < RuntimeError
  end

class GnipFileSizeExceeded < RuntimeError
end

class GnipImporter
  include ActiveModel::Validations
  include ChorusApiValidationFormat

  validate :validate_schema_and_table
  validate :workspace_must_have_sandbox

  attr_accessor :table_name, :gnip_data_source_id, :workspace, :user_id, :user, :event_id

  def self.import_to_table(table_name, gnip_data_source_id, workspace_id, user_id, event_id)
    importer = new(table_name, gnip_data_source_id, workspace_id, user_id, event_id)
    importer.import
  end

  def initialize(table_name, gnip_data_source_id, workspace_id, user_id, event_id)
    self.table_name = table_name
    self.gnip_data_source_id = gnip_data_source_id
    self.user_id = user_id
    self.user = User.find(user_id)
    self.event_id = event_id
    self.workspace = Workspace.find(workspace_id)
  end

  def import
    gnip_data_source = GnipDataSource.find(gnip_data_source_id)
    stream = ChorusGnip.from_stream(gnip_data_source.stream_url, gnip_data_source.username, gnip_data_source.password)

    first_time = true
    [*stream.fetch].each do |url|
      import_url_from_stream url, stream, first_time
      first_time = false
    end

    create_success_event

  rescue => e
    create_failure_event(e.message)
    raise e
  end

  def validate!
    raise ApiValidationError.new(errors) unless valid?
  end

  def validate_schema_and_table
    return unless workspace.sandbox
    db_connection = workspace.sandbox.database.connect_as(user)
    unless db_connection.schema_exists?(workspace.sandbox.name)
      errors.add(:workspace, :missing_sandbox)
      return
    end

    temp_csv_file = workspace.csv_files.new(
        :to_table => table_name
    )
    temp_csv_file.user = user
    if temp_csv_file.table_already_exists(table_name)
      errors.add(:table_name, :table_exists, { :table_name => table_name })
    end
  end

  def workspace_must_have_sandbox
    unless workspace.sandbox.present?
      errors.add(:workspace, :empty_sandbox)
    end
  end

  private

  def import_url_from_stream(url, stream, first_time)
    raise GnipException, JSON.parse($&)["reason"] if url =~ /^.*\"status\":\"error\".*$/
    result = stream.to_result_in_batches([url])
    csv_file = create_csv_file(result, first_time)
    csv_importer = CsvImporter.new(csv_file, event_id)
    csv_importer.import
  rescue => e
    cleanup_table
    raise e
  ensure
    csv_file.try(:destroy)
  end

  def max_file_size
    (ChorusConfig.instance["gnip.csv_import_max_file_size_mb"] || 50).megabytes
  end

  def cleanup_table
    workspace.sandbox.connect_with(account).drop_table(table_name)
  end

  def create_success_event
    gnip_event = Events::GnipStreamImportCreated.find(event_id).tap do |event|
      event.dataset = destination_dataset
      event.save!
    end

    event = Events::GnipStreamImportSuccess.by(gnip_event.actor).add(
        :workspace => gnip_event.workspace,
        :dataset => gnip_event.dataset,
        :gnip_data_source => gnip_event.gnip_data_source
    )
    Notification.create!(:recipient_id => gnip_event.actor.id, :event_id => event.id)
  end

  def create_failure_event(error_message)
    gnip_event = Events::GnipStreamImportCreated.find(event_id)
    event = Events::GnipStreamImportFailed.by(gnip_event.actor).add(
        :workspace => gnip_event.workspace,
        :destination_table => table_name,
        :gnip_data_source => gnip_event.gnip_data_source,
        :error_message => error_message
    )
    Notification.create!(:recipient_id => gnip_event.actor.id, :event_id => event.id)
  end

  def create_csv_file(result, first_time)
    workspace.csv_files.create!(
        {:contents => StringIO.new(result.contents),
         :column_names => result.column_names,
         :types => result.types,
         :delimiter => ',',
         :to_table => table_name,
         :new_table => first_time,
         :file_contains_header => false,
         :user_uploaded => false,
         :user_id => user_id
        },
        :without_protection => true).tap do |csv_file|
      if csv_file.contents_file_size > max_file_size
        raise GnipFileSizeExceeded, "Gnip download chunk exceeds maximum allowed file size for Gnip imports.  Consider increasing the system limit."
      end
    end
  end

  def destination_dataset
    workspace.sandbox.refresh_datasets(account)
    workspace.sandbox.datasets.find_by_name(table_name)
  end

  def account
    @account ||= begin
      workspace.sandbox.data_source.account_for_user!(user)
    end
  end
end
