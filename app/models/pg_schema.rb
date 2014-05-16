class PgSchema < Schema
  include SandboxSchema

  # TODO: dry out with gpdb schema
  attr_accessible :database
  alias_attribute :database, :parent
  delegate :data_source, :account_for_user!, :to => :database

  def class_for_type(type)
    type == 'r' ? PgTable : PgView
  end
end
