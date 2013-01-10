class DataSourceNameValidator < ActiveModel::Validator

  DATA_SOURCE_TYPES = [GpdbInstance, HadoopInstance, GnipInstance]

  def validate(record)
    if record.name && unique_name?(record)
      record.errors.add(:name, :in_use => record.name)
    end
  end

  private

  def unique_name?(record)
    DATA_SOURCE_TYPES.any? { |source_type|
      search = source_type.where('LOWER(name) = ?', record.name.downcase)
      search.reject { |model|
        model == record
      }.length > 0
    }
  end
end