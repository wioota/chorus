require_relative 'dataset_column'

class SqlResult
  attr_reader :columns, :rows
  attr_accessor :schema, :warnings

  def initialize(options = {})
    @columns = []
    @rows = []
    @warnings = options[:warnings] || []
    load_from_result_set(options[:result_set]) if options[:result_set]
  end

  def canceled?
    warnings.any? { |message| message =~ /cancel(ed|ing)/i }
  end

  def hashes
    rows.map do |row|
      hash = {}
      columns.each_with_index do |column, i|
        hash[column.name] = row[i]
      end
      hash
    end
  end

  def load_from_result_set(result_set)
    return unless result_set

    meta_data = result_set.meta_data

    (1..meta_data.column_count).each do |i|
      add_column(meta_data.get_column_name(i), meta_data.column_type_name(i))
    end

    while result_set.next
      row = (1..meta_data.column_count).map do |i|
        column_string_value meta_data, result_set, i
      end
      add_row(row)
    end
  end

  def column_string_value(meta_data, result_set, index)
    result_set.get_string(index).to_s
  end

  def add_column(name, type)
    @columns << dataset_column_class.new(:name => name, :data_type => type)
  end

  def add_row(row)
    @rows << row
  end

  def add_rows(rows)
    @rows.concat(rows)
  end
end
