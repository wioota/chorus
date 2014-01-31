class LicensePresenter < Presenter
  KEYS = [:admins, :developers, :collaborators, :level, :vendor, :organization_uuid, :expires]

  def to_hash
    KEYS.inject({}) do |memo, key|
      memo[key] = License.instance[key]
      memo
    end
  end
end
