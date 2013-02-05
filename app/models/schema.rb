class Schema < ActiveRecord::Base
  attr_accessible :name, :type
  belongs_to :parent, :polymorphic => true

  def self.find_and_verify_in_source(schema_id, user)
    schema = Schema.find(schema_id)
    raise ActiveRecord::RecordNotFound unless schema.verify_in_source(user)
    schema
  end
end