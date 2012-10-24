class CommentPresenter < Presenter

  def to_hash
    {
        :id => model.id,
        :author => present(model.author),
        :text => model.text,
        :action => 'SUB_COMMENT',
        :timestamp => model.created_at
    }
  end

  def complete_json?
    true
  end
end