require 'sequel/no_core_ext'

class ImportExecutor
  def self.run(import_id)
    import = Import.find(import_id)
    ImportExecutor.new(import).run if import.success.nil?
  end

  def self.cancel(import, success, message = nil)
    import.cancel(success, message)
  end

  def initialize(import)
    @import = import
  end

  def run
    import.touch(:started_at)
    # raises go into import#throw_if_not_runnable ?
    raise "Destination workspace #{import.workspace.name} has been deleted" if import.workspace_import? && import.workspace.deleted?
    raise "Original source dataset #{import.source_dataset.scoped_name} has been deleted" if import.source_dataset.deleted?

    import.generate_key if copier_class.requires_chorus_authorization?

    copier_class.new(import_attributes).start
    import.reload
    import.update_status :passed
  rescue => e
    import.reload
    import.update_status :failed, e.message
    raise
  end

  private

  def copier_class
    if import.source_dataset.class.name =~ /^Oracle/
      OracleTableCopier
    elsif import.source_dataset.database != import.schema.database
      CrossDatabaseTableCopier
    else
      TableCopier
    end
  end

  def import_attributes
    {
        :source_dataset => import.source_dataset,
        :destination_schema => import.schema,
        :destination_table_name => import.to_table,
        :user => import.user,
        :sample_count => import.sample_count,
        :truncate => import.truncate,
        :pipe_name => import.handle,
        :stream_url => stream_url
    }
  end

  def stream_url
    raise StandardError.new("Please set public_url in chorus.properties") if ChorusConfig.instance.public_url.nil?
    Rails.application.routes.url_helpers.external_stream_url(:dataset_id => import.source_dataset.id,
                                                             :row_limit => import.sample_count,
                                                             :host => ChorusConfig.instance.public_url,
                                                             :port => ChorusConfig.instance.server_port,
                                                             :stream_key => import.stream_key)
  end

  def import
    @import
  end
end