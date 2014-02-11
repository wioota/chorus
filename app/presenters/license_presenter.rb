class LicensePresenter < Presenter
  KEYS = [:admins, :developers, :collaborators, :level, :vendor, :organization_uuid, :expires]

  def to_hash
    KEYS.inject({}) do |memo, key|
      memo[key] = License.instance[key]
      memo
    end.merge({
            :workflow_enabled => License.instance.workflow_enabled?,
            :full_search_enabled => License.instance.full_search_enabled?,
            :branding => License.instance.branding
    })
  end
end
