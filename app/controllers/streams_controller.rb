class StreamsController < ApplicationController
  private

  def stream(dataset, user, options = {})
    streamer_options = options.symbolize_keys
    streamer_options[:row_limit] = streamer_options[:row_limit].to_i if streamer_options[:row_limit].to_i > 0

    @streamer = SqlStreamer.new(
        dataset.all_rows_sql(streamer_options[:row_limit]),
        dataset.connect_as(user),
        streamer_options
    )

    response.headers["Content-Disposition"] = "attachment; filename=#{dataset.name}.csv"
    response.headers["Cache-Control"] = 'no-cache'
    response.headers["Transfer-Encoding"] = 'chunked'

    begin
      self.response_body = @streamer.enum
    rescue ActiveRecord::RecordNotFound => e
      self.response_body = e.message
    end
  end
end
