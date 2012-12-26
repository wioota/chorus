
class SearchPresenter < SearchPresenterBase

  def to_hash
    {
        :users => {
            :results => present_models_with_highlights(model.users),
            :numFound => model.users.length
        },

        :instances => {
            :results => present_models_with_highlights(model.instances),
            :numFound => model.instances.length
        },

        :workspaces => {
            :results => present_models_with_highlights(model.workspaces),
            :numFound => model.workspaces.length
        },

        :workfiles => {
            :results => present_models_with_highlights(model.workfiles),
            :numFound => model.workfiles.length
        },

        :datasets => {
            :results => present_models_with_highlights(model.datasets),
            :numFound => model.datasets.length
        },

        :hdfs_entries => {
            :results => present_models_with_highlights(model.hdfs_entries),
            :numFound => model.hdfs_entries.length
        },

        :attachment => {
            :results => present_models_with_highlights(model.attachments),
            :numFound => model.attachments.length
        }
    }.merge(workspace_specific_results)
  end

  private

  def workspace_specific_results
    if model.workspace_id
      {
          :this_workspace => {
              :results => present_workspace_models_with_highlights(model.this_workspace),
              :numFound => model.this_workspace.length
          }
      }
    else
      {}
    end
  end
end
