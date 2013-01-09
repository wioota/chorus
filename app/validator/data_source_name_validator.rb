class DataSourceNameValidator < ActiveModel::Validator

  DATA_SOURCE_TYPES = [GpdbInstance, HadoopInstance, GnipInstance]

  def validate(record)
    if unique_name?(record.name)
      record.errors.add(:name, :in_use)
    end
  end

  private

  def unique_name?(name)
    DATA_SOURCE_TYPES.any? { |source_type| source_type.where('LOWER(name) = ?', name.downcase) }
  end
end