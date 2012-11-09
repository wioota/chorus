class CsvWriter
  def self.to_csv(columns, rows)
    output_result = columns.to_csv
    rows.each do |row|
      output_result = output_result + row.to_csv
    end
    output_result
  end
end