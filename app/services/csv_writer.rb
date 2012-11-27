class CsvWriter
  def self.to_csv(columns, rows)
    output_result = columns.to_csv
    rows.each do |row|
      output_result = output_result + row.to_csv
    end
    output_result
  end

  def self.to_csv_as_stream(columns, rows)
    Enumerator.new do |y|
      y << columns.to_csv
      rows.each do |row|
        y << row.to_csv
      end
    end
  end
end