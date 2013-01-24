class GpdbViewAccess < AdminFullAccess
  def show?(gpdb_view)
    GpdbDataSourceAccess.new(context).can? :show, gpdb_view.gpdb_data_source
  end
end