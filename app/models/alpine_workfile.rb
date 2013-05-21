class AlpineWorkfile < Workfile
  has_additional_data :database_id
  validates_presence_of :database_id

  def entity_subtype
    'alpine'
  end
end