class SchemaImport < Import
  belongs_to :schema
  validates :schema, :presence => true
end