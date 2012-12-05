module Gpdb
  class InstanceRegistrar
    InvalidInstanceError = Class.new(StandardError)

    def self.create!(connection_config, owner)
      config = connection_config.merge(:instance_provider => "Greenplum Database")
      gpdb_instance = owner.gpdb_instances.build(config)
      gpdb_instance.shared = config[:shared]

      account = owner.instance_accounts.build(config)
      ActiveRecord::Base.transaction do
        gpdb_instance.save!
        account.gpdb_instance = gpdb_instance
        ConnectionChecker.check!(gpdb_instance, account)
        gpdb_instance.save!
        account.save!
      end

      Events::GreenplumInstanceCreated.by(owner).add(:gpdb_instance => gpdb_instance)

      gpdb_instance
    end

    def self.update!(gpdb_instance, connection_config, updater)
      raise InvalidInstanceError if gpdb_instance.nil?
      gpdb_instance.attributes = connection_config

      ConnectionChecker.check!(gpdb_instance, gpdb_instance.owner_account)

      if gpdb_instance.name_changed?
        Events::GreenplumInstanceChangedName.by(updater).add(
          :gpdb_instance => gpdb_instance,
          :old_name => gpdb_instance.name_was,
          :new_name => gpdb_instance.name
        )
      end

      gpdb_instance.save!
      gpdb_instance
    end
  end
end
