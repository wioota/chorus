class NotificationPresenter < Presenter
  def to_hash
    event_presenter = EventPresenter.new(model.event, @view_context, :activity_stream => true)
    {
        :id => model.id,
        :recipient => present(model.recipient, @options),
        :event => event_presenter.simple_hash,
        :comment => present(model.comment),
        :unread => !(model.read),
        :timestamp => model.created_at
    }
  end

  def complete_json?
    true
  end
end