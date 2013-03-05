class StreamsController < ApplicationController
  private

  def stream(dataset, user, options = {})
    streamer_options = options.symbolize_keys

    @streamer = DatasetStreamer.new(dataset, user, streamer_options)
    response.headers["Content-Disposition"] = "attachment; filename=#{dataset.name}.csv"
    response.headers["Cache-Control"] = 'no-cache'
    response.headers["Transfer-Encoding"] = 'chunked'
    begin
      self.response_body = @streamer.enum(streamer_options[:header].to_s == 'true')
    rescue ActiveRecord::RecordNotFound => e
      self.response_body = e.message
    end
  end
end
