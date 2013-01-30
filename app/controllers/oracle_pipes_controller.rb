class OraclePipesController < ApplicationController
  skip_before_filter :require_login

  def show
    #none of this is tested, it is just scaffolding for OracleImportController
    @streamer = OracleDatasetStreamer.new
    response.headers["Content-Disposition"] = "attachment; filename=oracle.csv"
    response.headers["Cache-Control"] = 'no-cache'
    response.headers["Transfer-Encoding"] = 'chunked'
    begin
      self.response_body = @streamer.enum
    rescue ActiveRecord::RecordNotFound => e
      self.response_body = e.message
    end
  end
end