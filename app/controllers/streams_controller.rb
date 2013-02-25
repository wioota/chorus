class StreamsController < ApplicationController
  private

  def stream(dataset, user, row_limit, include_header_row)
    @streamer = DatasetStreamer.new(dataset, user, row_limit)
    response.headers["Content-Disposition"] = "attachment; filename=#{dataset.name}.csv"
    response.headers["Cache-Control"] = 'no-cache'
    response.headers["Transfer-Encoding"] = 'chunked'
    begin
      self.response_body = @streamer.enum(include_header_row.to_s != 'false')
    rescue ActiveRecord::RecordNotFound => e
      self.response_body = e.message
    end
  end
end
