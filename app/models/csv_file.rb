class CsvFile < ActiveRecord::Base
  attr_accessible :contents, :column_names, :types, :delimiter, :to_table, :file_contains_header, :new_table, :truncate

  serialize :column_names
  serialize :types

  belongs_to :workspace
  belongs_to :user

  has_attached_file :contents, :path => ":rails_root/system/:class/:id/:basename.:extension"

  validates :contents, :attachment_presence => true
  validates_attachment_size :contents,
    :less_than => ChorusConfig.instance['file_sizes_mb']['csv_imports'].megabytes,
    :message => :file_size_exceeded,
    :if => :user_uploaded

  validates :user, :presence => true
  validates :workspace, :presence => true

  def escaped_column_names
    column_names.map { |column_name| %Q|"#{column_name}"| }
  end

  def self.delete_old_files!
    age_limit = ChorusConfig.instance['delete_unimported_csv_files_after_hours']
    return unless age_limit
    CsvFile.where("created_at < ?", Time.current - age_limit.hours).destroy_all
  end

  def table_already_exists(table_name)
    schema = workspace.sandbox
    account = schema.gpdb_instance.account_for_user!(user)
    check_table(table_name, account, schema)
  end

  def ready_to_import?
    to_table.present? && column_names.present? && types.present? && file_contains_header != nil &&
    delimiter != nil && delimiter.length > 0 && valid?
  end

  private

  def check_table(table_name, account, schema)
    schema.with_gpdb_connection(account) do |connection|
      check_results = connection.exec_query <<-SQL
        SELECT table_name
        FROM information_schema.tables
        WHERE table_name = '#{table_name}' AND table_schema = '#{schema.name}'
      SQL
      check_results.count > 0
    end
  end
end
