class OracleImportExecutor
  def initialize(params)
    @schema = params[:schema]
    @user = params[:user]
    @table_name = params[:table_name]
    @url = params[:url]
  end

  def run
    #get column names from oracle table
    columns = DatasetColumn.columns_for(@schema.account_for_user!(@user), @dataset)

    #create external table to stream oracle data into
    @schema.connect_as(@user).create_external_table({
        :location_url => @url,
        :web => true,
        :columns => "col1 int, col2 int, col3 int",
        :table_name => ext_table_name,
        :delimiter => ','
    })

    #create destination table in greenplum

    #copy data from external table to destination table

    #delete external table
  end

  def ext_table_name
    @table_name + "_ext"
  end
end