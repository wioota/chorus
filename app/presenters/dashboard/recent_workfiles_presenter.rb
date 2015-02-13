module Dashboard
  class RecentWorkfilesPresenter < BasePresenter
    private

    def data
      if model.result != nil
        model.result.map do |event|
          {
              :last_opened => event.created_at,
              # Adding cached and namespace options to cache to JSON data to speed up subsequent queries.
              :workfile => present(event.workfile, { :workfile_as_latest_version => true, :list_view => true, :cached => true, :namespace => "dashboard:recentworkfiles"})
          }
        end
      end
    end
  end
end
