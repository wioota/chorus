class CommentPresenter < Presenter

  def to_hash
    {
        :id => model.id,
        :author => present(model.author),
        :body => model.body,
        :action => 'SUB_COMMENT',
        :timestamp => model.created_at
    }
  end

  def complete_json?
    true
  end
end