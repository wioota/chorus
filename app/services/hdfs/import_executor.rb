module Hdfs
  class ImportExecutor
    attr_accessor :import, :directory

    def self.run(hdfs_import_id)
      import = HdfsImport.find hdfs_import_id
      new(import: import).run
    end

    def initialize(params)
      @import = params[:import]
      @directory = import.hdfs_entry
    end

    def run
      query_service = QueryService.for_data_source(directory.hdfs_data_source)
      query_service.import_data(import.destination_path, stream)

      create_success_event
    rescue StandardError => e
      Chorus.log_error %(Hdfs::ImportExecutor import failed: #{e.message})
    ensure
      import.destroy
    end

    private

    def stream
      java.io.FileInputStream.new(import.upload.contents.path)
    end

    def create_success_event
      directory.refresh
      entry = HdfsEntry.find_by_path import.destination_path

      event = Events::HdfsImportSuccess.by(import.user).add(:hdfs_entry => entry, :hdfs_data_source => entry.hdfs_data_source)
      notify_user(event)
    end

    def notify_user(event)
      Notification.create!(:event => event, :recipient => import.user)
    end
  end
end
