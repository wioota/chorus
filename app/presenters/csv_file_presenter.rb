class CsvFilePresenter < Presenter
  def to_hash
    {
        :id => model.id,
        :contents => contents
    }
  rescue => e
    model.errors.add(:contents, :FILE_INVALID)
    raise ActiveRecord::RecordInvalid.new(model)
  end

  def contents
    #not tested in rspec,
    #but this needs to handle very large files without crashing the server
    output = []

    File.open(model.contents.path) do | file|
      file.each_line do |line|
        break if file.lineno > 100
        output << line.gsub(/\n$/, '')
      end
    end
    output
  end

  def complete_json?
    true
  end
end