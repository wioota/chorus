class JobPresenter < Presenter

  def to_hash
    job = {
      :id => model.id,
      :workspace => present(model.workspace, options.merge(:succinct => options[:succinct] || options[:list_view])),
      :name => model.name,
      :next_run => model.next_run,
      :last_run => model.last_run,
      :frequency => model.frequency,
      :state => model.enabled ? 'scheduled' : 'disabled',
      :tasks => [
        {id: 901,   index: 1, name: 'Get the Groceries', type: 'import_source_data'},
        {id: 10201, index: 2, name: 'Wash the Car', type: 'run_work_flow'},
        {id: 44101, index: 3, name: 'Fix my Bike', type: 'run_sql_file'},
      ]
    }
    job
  end
end
