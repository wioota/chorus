module JdbcHive
  class DataSourceRegistrar

    def self.create!(data_source_attributes, owner)
      data_source = JdbcHiveDataSource.new(data_source_attributes)
      data_source[:shared] = data_source_attributes[:shared]
      data_source.owner = owner
      data_source.save!
      Events::DataSourceCreated.by(owner).add(:data_source => data_source)
      data_source
    end

    def self.update!(data_source_id, data_source_attributes)
      data_source = JdbcHiveDataSource.find(data_source_id)

      data_source_attributes.delete(:owner)

      data_source.attributes = data_source_attributes
      data_source.save!
      data_source

    end
  end
end