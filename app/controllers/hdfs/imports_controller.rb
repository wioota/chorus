module Hdfs
  class ImportsController < ::ApplicationController
    def create
      authorize! :use, upload

      hdfs_import = HdfsImport.new(:hdfs_entry => hdfs_entry, :upload => upload, :file_name => file_name)
      hdfs_import.user = current_user
      hdfs_import.save!

      QC.enqueue_if_not_queued('Hdfs::ImportExecutor.run', hdfs_import.id)

      present hdfs_import, :status => :created
    end

    private

    def hdfs_entry
      @hdfs_entry ||= HdfsEntry.find params[:file_id]
    end

    def upload
      @upload ||= Upload.find params[:upload_id]
    end

    def file_name
      params[:file_name]
    end
  end
end
