module DataSources
  class OwnerController < ApplicationController
    def update
      authorize! :edit, gpdb_instance
      Gpdb::InstanceOwnership.change(current_user, gpdb_instance, new_owner)
      present gpdb_instance
    end

    private

    def new_owner
      User.find(params[:owner][:id])
    end

    def gpdb_instance
      @gpdb_instance ||= GpdbInstance.owned_by(current_user).find(params[:data_source_id])
    end
  end
end
