class DeveloperCountValidator < ActiveModel::Validator
  include LicenseValidations

  def validate(record)
    with_license do |license|
      if record.developer? && (User.developer_count + num_new(record)) > license[:developers]
        record.errors.add(:developer, :license_limit_exceeded)
      end
    end
  end

  def num_new(record)
    record.developer_changed? ? 1 : 0
  end
end
