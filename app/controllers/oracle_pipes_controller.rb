class OraclePipesController < ApplicationController
  skip_before_filter :require_login

  def show
    #none of this is tested, it is just scaffolding for OracleImportController
    response.headers["Content-Disposition"] = "attachment; filename=oracle.csv"
    response.headers["Cache-Control"] = 'no-cache'
    response.headers["Transfer-Encoding"] = 'chunked'
    begin
      self.response_body = "1,2,3\n4,5,6\n7,8,9"
    end
  end
end