class CsvFilePresenter < Presenter
  def to_hash
    {
        :id => model.id,
        :contents => File.readlines(model.contents.path).map{ |line| line.gsub(/\n$/, '') }[0..99],
        :entity_type => model.entity_type_name
    }
  rescue => e
    model.errors.add(:contents, :FILE_INVALID)
    raise ActiveRecord::RecordInvalid.new(model)
  end

  def complete_json?
    true
  end
end