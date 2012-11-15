class GpdbViewAccess < AdminFullAccess
  def show?(gpdb_view)
    GpdbInstanceAccess.new(context).can? :show, gpdb_view.gpdb_instance
  end
end