class GpdbDatabase < Database

  has_many :schemas, :class_name => 'GpdbSchema', :as => :parent, :dependent => :destroy
  has_many :datasets, :through => :schemas

  def create_schema(name, current_user)
    new_schema = GpdbSchema.new(:name => name, :database => self)
    raise ActiveRecord::RecordInvalid.new(new_schema) if new_schema.invalid?

    connect_as(current_user).create_schema(name)
    GpdbSchema.refresh(account_for_user!(current_user), self)
    schemas.find_by_name!(name)
  end
end
