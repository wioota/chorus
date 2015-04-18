class OracleSqlResultPresenter < SqlResultPresenter
  def to_hash
    hash = super

    # Fix for DEV-8799. 'Server Error' when trying to do a SQL execute on Oracle.
    # if date or time is wrongly formmatted in database, pass date in raw format.

    begin
      reformat_values(hash, "date") do |value|
        DateTime.parse(value).strftime("%-m/%d/%Y")
      end
      reformat_values(hash, "timestamp") do |value|
        DateTime.parse(value).strftime("%-m/%d/%Y%l:%M:%S.%3N %p")
      end
    rescue ArgumentError => e
      Chorus.log_error "Invalid date OR time format: #{e}: #{e.message} on #{e.backtrace[0]}"
    end

    hash
  end

  private

  def reformat_values(hash, type, &block)
    index = 0
    columns = hash[:columns].reduce([]) do |indexes, column|
      if column[:data_type] == type
        indexes << index
      end

      index = index + 1
      indexes
    end

    hash[:rows].map do |row|
      columns.each do |i|
        row[i] = block.call(row[i])
      end
    end
  end
end