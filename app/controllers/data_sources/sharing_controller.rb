module DataSources
  class SharingController < ApplicationController
    def create
      authorize! :edit, gpdb_data_source

      gpdb_data_source.shared = true
      gpdb_data_source.accounts.where("id != #{gpdb_data_source.owner_account.id}").destroy_all
      gpdb_data_source.save!
      present gpdb_data_source, :status => :created
    end

    def destroy
      authorize! :edit, gpdb_data_source

      gpdb_data_source.shared = false
      gpdb_data_source.save!
      present gpdb_data_source
    end

    private

    def gpdb_data_source
      @gpdb_data_source ||= GpdbDataSource.find(params[:data_source_id])
    end
  end
end