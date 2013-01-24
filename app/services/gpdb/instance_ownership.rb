module Gpdb
  InvalidOwnerError = Class.new(RuntimeError)

  module InstanceOwnership
    class << self

      def change(updater, gpdb_data_source, new_owner)
        if gpdb_data_source.shared?
          change_owner_of_shared(gpdb_data_source, new_owner)
        else
          change_owner_of_unshared(gpdb_data_source, new_owner)
        end

        Events::GreenplumInstanceChangedOwner.by(updater).add(
          :gpdb_data_source => gpdb_data_source,
          :new_owner => new_owner
        )
      end

      private

      def change_owner_of_shared(gpdb_data_source, new_owner)
        ActiveRecord::Base.transaction do
          owner_account = gpdb_data_source.owner_account
          owner_account.owner = new_owner
          owner_account.save!
          gpdb_data_source.owner = new_owner
          gpdb_data_source.save!
        end
      end

      def change_owner_of_unshared(gpdb_data_source, new_owner)
        ensure_user_has_account(gpdb_data_source, new_owner)
        gpdb_data_source.owner = new_owner
        gpdb_data_source.save!
      end

      def ensure_user_has_account(gpdb_data_source, new_owner)
        gpdb_data_source.account_for_user!(new_owner)
      end

    end
  end
end
