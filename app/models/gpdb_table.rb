require 'dataset'

class GpdbTable < GpdbDataset
  belongs_to :schema, :class_name => 'GpdbSchema'

  def analyze(account)
    schema.connect_with(account).analyze_table(name)
  end


  def verify_in_source(user)
    schema.connect_as(user).table_exists?(name)
  end
end
