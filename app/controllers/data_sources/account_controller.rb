module DataSources
  class AccountController < ApplicationController
    def show
      present GpdbInstance.find(params[:data_source_id]).account_for_user(current_user)
    end

    def create
      present updated_account, :status => :created
    end

    def update
      present updated_account, :status => :ok
    end

    def destroy
      gpdb_instance = GpdbInstance.unshared.find(params[:data_source_id])
      gpdb_instance.account_for_user(current_user).destroy
      render :json => {}
    end

    private

    def updated_account
      gpdb_instance = GpdbInstance.unshared.find(params[:data_source_id])

      account = gpdb_instance.accounts.find_or_initialize_by_owner_id(current_user.id)
      account.attributes = params[:account]
      account.save!
      account
    end
  end
end
