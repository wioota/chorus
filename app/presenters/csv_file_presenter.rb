require 'csv'

class CsvFilePresenter < Presenter
  def to_hash
    {
        :id => model.id,
        :contents => contents,
        :entity_type => model.entity_type_name
    }
  rescue => e
    model.errors.add(:contents, :FILE_INVALID)
    raise ActiveRecord::RecordInvalid.new(model)
  end

  def contents
    i = 0
    result = []
    CSV.foreach(model.contents.path) do |row|
      break if i > 99
      result << row.to_csv
      i = i + 1
    end
    result
  end

  def complete_json?
    true
  end
end