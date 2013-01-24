module DataSources
  class OwnerController < ApplicationController
    def update
      authorize! :edit, gpdb_data_source
      Gpdb::InstanceOwnership.change(current_user, gpdb_data_source, new_owner)
      present gpdb_data_source
    end

    private

    def new_owner
      User.find(params[:owner][:id])
    end

    def gpdb_data_source
      @gpdb_data_source ||= GpdbDataSource.owned_by(current_user).find(params[:data_source_id])
    end
  end
end
