class GreenplumConnection < PostgresLikeConnection
  private

  def version_prefix
    'Greenplum Database'
  end
end
