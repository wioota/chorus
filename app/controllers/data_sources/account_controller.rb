module DataSources
  class AccountController < ApplicationController
    def show
      present GpdbDataSource.find(params[:data_source_id]).account_for_user(current_user)
    end

    def create
      present updated_account, :status => :created
    end

    def update
      present updated_account, :status => :ok
    end

    def destroy
      gpdb_data_source = GpdbDataSource.unshared.find(params[:data_source_id])
      gpdb_data_source.account_for_user(current_user).destroy
      render :json => {}
    end

    private

    def updated_account
      gpdb_data_source = GpdbDataSource.unshared.find(params[:data_source_id])

      account = gpdb_data_source.accounts.find_or_initialize_by_owner_id(current_user.id)
      account.attributes = params[:account]
      account.save!
      account
    end
  end
end
