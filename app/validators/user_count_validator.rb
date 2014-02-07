class UserCountValidator < ActiveModel::Validator
  include LicenseValidations

  def validate(record)
    with_license do |license|
      record.errors.add(:user, :license_limit_exceeded) if User.count >= license[:collaborators]
    end
  end

end
