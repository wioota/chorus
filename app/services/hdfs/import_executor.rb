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
      query_service.import_data(destination_path, stream)
    rescue StandardError => e
      Chorus.log_error %(Hdfs::ImportExecutor import failed: #{e.message})
    ensure
      import.destroy
    end

    private

    def destination_path
      %(#{directory.path.chomp('/')}/#{import.destination_file_name})
    end

    def stream
      java.io.FileInputStream.new(import.upload.contents.path)
    end
  end
end
