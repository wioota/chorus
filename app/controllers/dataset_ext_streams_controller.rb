class DatasetExtStreamsController < ApplicationController
  skip_before_filter :require_login
  include DataSourceAuth

  def show
    return head :unauthorized unless params[:stream_key]

    import = Import.find_by_stream_key(params[:stream_key])
    return head :unauthorized unless import
    dataset = import.source_dataset

    @streamer = DatasetStreamer.new(dataset, import.user, params[:row_limit])
    response.headers["Content-Disposition"] = "attachment; filename=#{dataset.name}.csv"
    response.headers["Cache-Control"] = 'no-cache'
    response.headers["Transfer-Encoding"] = 'chunked'
    begin
      self.response_body = @streamer.enum(false)
    rescue ActiveRecord::RecordNotFound => e
      self.response_body = e.message
    end
  end
end