module Oracle
  class InstanceRegistrar
    def self.create!(connection_config, owner)
      instance = OracleInstance.create!(connection_config)
      #account = instance.accounts.build(config.merge(:owner => owner))
      instance
    end
  end
end