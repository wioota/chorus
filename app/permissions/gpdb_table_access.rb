class GpdbTableAccess < AdminFullAccess
  def show?(gpdb_table)
    GpdbInstanceAccess.new(context).can? :show, gpdb_table.gpdb_instance
  end
end
