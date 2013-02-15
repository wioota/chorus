class CsvImporter
  class ImportFailed < StandardError; end

  attr_accessor :csv_file, :schema, :account, :import_created_event_id, :import_record

  CREATE_TABLE_STRING = Rails.env.test? ? 'create temporary table' : 'create table'

  def self.import_file(csv_file_id, import_created_event_id)
    csv_importer = new(CsvFile.find(csv_file_id), import_created_event_id)
    csv_importer.import_with_events
  ensure
    csv_importer.csv_file.destroy
  end

  def initialize(csv_file, import_created_event_id)
    self.csv_file = csv_file
    self.import_created_event_id = import_created_event_id
    self.schema = csv_file.workspace.sandbox
    self.account = schema.data_source.account_for_user!(csv_file.user)
  end

  def import_with_events
    import
    create_success_event
    import_record.update_attribute(:success, true)
  rescue ImportFailed => e
    create_failure_event(e.message)
    import_record.try(:update_attribute, :success, false)
    raise e
  ensure
    import_record.try(:touch, :finished_at)
  end

  def import
    self.import_record = create_csv_import

    raise StandardError, "CSV file cannot be imported" unless csv_file.ready_to_import?
    schema.connect_as(csv_file.user) do |connection|
      begin
        it_exists = check_if_table_exists(csv_file.to_table, csv_file)
        if csv_file.new_table
          connection.prepare_and_execute_statement("CREATE TABLE #{csv_file.to_table}(#{create_table_sql})")
        end

        connection.truncate_table(csv_file.to_table) if csv_file.truncate

        connection.connect!.synchronize do |jdbc_conn|
          copy_manager = org.postgresql.copy.CopyManager.new(jdbc_conn)
          destination_table_name = %Q{"#{schema.name}"."#{csv_file.to_table}"}
          sql = "COPY #{destination_table_name}(#{column_names_sql}) FROM STDIN WITH DELIMITER '#{csv_file.delimiter}' CSV #{header_sql}"
          copy_manager.copy_in(sql, java.io.FileReader.new(csv_file.contents.path))
        end
        schema.refresh_datasets(account)
      rescue Exception => e
        schema.connect_as(csv_file.user).drop_table(csv_file.to_table) if csv_file.new_table && it_exists == false
        raise e
      end
    end

    import_record.success = true
  rescue Exception => e
    import_record.success = false
    raise ImportFailed.new(e.message)
  ensure
    import_record.destination_dataset = destination_dataset
    import_record.finished_at = Time.current
    import_record.save!(:validate => false)
  end

  def create_csv_import
    i = Import.new(
        :file_name => csv_file.contents_file_name,
        :to_table => csv_file.to_table,
        :new_table => csv_file.new_table,
        :truncate => csv_file.truncate,
    )
    i.workspace_id = csv_file.workspace_id
    i.user_id = csv_file.user_id
    i.save
    i
  end

  def check_if_table_exists(table_name, csv_file)
    csv_file.table_already_exists(table_name)
  end

  def create_success_event
    Events::FileImportCreated.find(import_created_event_id).tap do |event|
      event.dataset = destination_dataset
      event.save!
    end

    event = Events::FileImportSuccess.by(csv_file.user).add(
        :workspace => csv_file.workspace,
        :dataset => destination_dataset,
        :file_name => csv_file.contents_file_name,
        :import_type => 'file'
    )

    Notification.create!(:recipient_id => csv_file.user.id, :event_id => event.id)
  end

  def create_failure_event(error_message)
    event = Events::FileImportFailed.by(csv_file.user).add(
        :workspace => csv_file.workspace,
        :file_name => csv_file.contents_file_name,
        :import_type => 'file',
        :destination_table => csv_file.to_table,
        :error_message => error_message,
        :dataset => destination_dataset
    )

    Notification.create!(:recipient_id => csv_file.user.id, :event_id => event.id)
  end

  def destination_dataset
    schema.datasets.tables.find_by_name(csv_file.to_table)
  end

  # column_mapping is direct postgresql types
  def create_table_sql
    csv_file.escaped_column_names.zip(csv_file.types).map{|a,b| "#{a} #{b}"}.join(", ")
  end

  def column_names_sql
    csv_file.escaped_column_names.join(', ')
  end

  def header_sql
    csv_file.file_contains_header ? "HEADER" : ""
  end
end
