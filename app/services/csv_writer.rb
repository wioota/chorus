class CsvWriter
  def self.to_csv_as_stream(columns, rows)
    Enumerator.new do |y|
      y << columns.to_csv
      rows.each do |row|
        y << row.to_csv
      end
    end
  end
end