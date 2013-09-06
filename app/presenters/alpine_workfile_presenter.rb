class AlpineWorkfilePresenter < WorkfilePresenter

  def to_hash
    workfile = super
    if options[:workfile_as_latest_version]
      workfile[:version_info] = {
          :created_at => model.created_at,
          :updated_at => model.updated_at
      }
    end

    unless options[:list_view]
      workfile[:execution_locations] = present(model.execution_locations, :succinct => true)
    end

    workfile
  end
end
