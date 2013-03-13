class ExternalStreamsController < StreamsController
  skip_before_filter :require_login
  include DataSourceAuth

  def show
    return head :unauthorized unless params[:stream_key]
    import = Import.find_by_stream_key(params[:stream_key])
    return head :unauthorized unless import

    stream_options = params.slice(:row_limit).merge(target_is_greenplum: true, show_headers: false)
    stream(import.source_dataset, import.user, stream_options)
  end
end