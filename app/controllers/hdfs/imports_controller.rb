module Hdfs
  class ImportsController < ::ApplicationController
    def create
      authorize! :use, upload

      hdfs_import = HdfsImport.new(:hdfs_entry => hdfs_entry, :upload => upload)
      hdfs_import.user = current_user
      hdfs_import.save!

      present hdfs_import, :status => :created
    end

    private

    def hdfs_entry
      @hdfs_entry ||= HdfsEntry.find params[:file_id]
    end

    def upload
      @upload ||= Upload.find params[:upload_id]
    end
  end
end
