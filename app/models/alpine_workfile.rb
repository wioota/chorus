class AlpineWorkfile < Workfile
  has_additional_data :alpine_id
  validates_presence_of :alpine_id

  def entity_type
    'alpine'
  end
end