module GpdbTestHelpers
  def stub_gpdb(account, query_values)
    any_instance_of(GreenplumConnection) do |instance|
      query_values.each do |query, response|
        stub(instance).prepare_and_execute_statement(query).times(any_times) {
          SqlResult.new.tap do |result|
            result_set = clone_response(response)
            keys = result_set[0].keys
            keys.each do |key|
              value = result_set[0][key]
              result.add_column(key, value.is_a?(Integer) ? "integer" : "string")
            end
            result_set.each do |row|
              result.add_row(keys.map {|key| row[key]} )
            end
          end
        }
      end
    end
  end

  def stub_gpdb_fail
    any_instance_of(GreenplumConnection) do |instance|
      stub(instance).prepare_and_execute_statement.with_any_args { raise ActiveRecord::JDBCError }
    end
  end

  def clone_response(response)
    return response.call if response.respond_to?(:call)
    response.map(&:clone)
  end
end
