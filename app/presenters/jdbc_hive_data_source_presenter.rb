class JdbcHiveDataSourcePresenter < JdbcDataSourcePresenter
  def to_hash
    hash = super
    hash.merge!({
        :hive => model.hive,
        :hive_kerberos => model.hive_kerberos,
        :hive_kerberos_principal => model.hive_kerberos_principal,
        :hive_hadoop_version => model.hive_hadoop_version,
        :hive_kerberos_keytab_location => model.hive_kerberos_keytab_location
    })
    hash
  end

  def complete_json?
    !rendering_activities? && !succinct?
  end

  private

  def tags_hash
    rendering_activities? ? {} : {:tags => present(model.tags)}
  end

  def owner_hash
    if rendering_activities?
      {}
    else
      {:owner => model.owner}
    end
  end
end
