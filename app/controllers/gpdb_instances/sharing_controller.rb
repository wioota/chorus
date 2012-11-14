module GpdbInstances
  class SharingController < ApplicationController
    def create
      authorize! :edit, gpdb_instance

      gpdb_instance.shared = true
      gpdb_instance.accounts.where("id != #{gpdb_instance.owner_account.id}").destroy_all
      gpdb_instance.save!
      present gpdb_instance, :status => :created
    end

    def destroy
      authorize! :edit, gpdb_instance

      gpdb_instance.shared = false
      gpdb_instance.save!
      present gpdb_instance
    end

    private

    def gpdb_instance
      @gpdb_instance ||= GpdbInstance.find(params[:gpdb_instance_id])
    end
  end
end