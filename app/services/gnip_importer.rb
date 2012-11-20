class GnipException < RuntimeError
  end

class GnipFileSizeExceeded < RuntimeError
end

class GnipImporter
  attr_accessor :table_name, :gnip_instance_id, :workspace_id, :user_id, :event_id, :workspace

  def self.import_to_table(table_name, gnip_instance_id, workspace_id, user_id, event_id)
    importer = new(table_name, gnip_instance_id, workspace_id, user_id, event_id)
    importer.import
  end

  def initialize(table_name, gnip_instance_id, workspace_id, user_id, event_id)
    self.table_name = table_name
    self.gnip_instance_id = gnip_instance_id
    self.workspace_id = workspace_id
    self.user_id = user_id
    self.event_id = event_id
    self.workspace = Workspace.find(workspace_id)
  end

  def import
    gnip_instance = GnipInstance.find(gnip_instance_id)
    stream = ChorusGnip.from_stream(gnip_instance.stream_url, gnip_instance.username, gnip_instance.password)

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

  private

  def import_url_from_stream(url, stream, first_time)
    raise GnipException, JSON.parse($&)["reason"] if url =~ /^.*\"status\":\"error\".*$/
    result = stream.to_result_in_batches([url])
    csv_file = create_csv_file(result, first_time)
    csv_importer = CsvImporter.new(csv_file.id, event_id)
    csv_importer.import
  rescue => e
    cleanup_table
    raise e
  ensure
    csv_file.try(:destroy)
  end

  def max_file_size
    (Chorus::Application.config.chorus["gnip.csv_import_max_file_size_mb"] || 50).megabytes
  end

  def cleanup_table
    workspace.sandbox.with_gpdb_connection(account) do |connection|
      connection.exec_query("DROP TABLE IF EXISTS #{table_name}")
    end
  end

  def create_success_event
    gnip_event = Events::GnipStreamImportCreated.find(event_id).tap do |event|
      event.dataset = destination_dataset
      event.save!
    end

    event = Events::GnipStreamImportSuccess.by(gnip_event.actor).add(
        :workspace => gnip_event.workspace,
        :dataset => gnip_event.dataset,
        :gnip_instance => gnip_event.gnip_instance
    )
    Notification.create!(:recipient_id => gnip_event.actor.id, :event_id => event.id)
  end

  def create_failure_event(error_message)
    gnip_event = Events::GnipStreamImportCreated.find(event_id)
    event = Events::GnipStreamImportFailed.by(gnip_event.actor).add(
        :workspace => gnip_event.workspace,
        :destination_table => table_name,
        :gnip_instance => gnip_event.gnip_instance,
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
    Dataset.refresh(account, workspace.sandbox)
    workspace.sandbox.datasets.find_by_name(table_name)
  end

  def account
    @account ||= begin
      user = User.find(user_id)
      workspace.sandbox.gpdb_instance.account_for_user!(user)
    end
  end
end
