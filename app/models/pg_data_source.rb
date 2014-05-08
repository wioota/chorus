class PgDataSource < ConcreteDataSource
  include PostgresLikeDataSourceBehavior

  def self.create_for_user(user, data_source_hash)
    user.pg_data_sources.create!(data_source_hash, :as => :create)
  end

  def data_source_provider
    'PostgreSQL Database'
  end
end
