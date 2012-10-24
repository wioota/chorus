class TypeAheadSearchPresenter < SearchPresenterBase

  def to_hash
    {
        type_ahead: {
            results:
                present_models_with_highlights(model.results)
        }
    }
  end
end
