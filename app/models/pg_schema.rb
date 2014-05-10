class PgSchema < Schema
  # TODO: dry out with gpdb schema
  attr_accessible :database
  alias_attribute :database, :parent
  delegate :data_source, :account_for_user!, :to => :database
end
