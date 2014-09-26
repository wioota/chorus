module Dashboard
  class WorkspaceActivity < DataModule

    def fetch_results
      num_days = 7
      num_workspaces = 10
      start_date = num_days.days.ago.at_beginning_of_day

      # Get the top 10 workspaces since start_date
      top_workspace_ids = Events::Base
        .select('workspace_id, count(*) as event_count')
        .group(:workspace_id)
        .where('workspace_id IS NOT NULL')
        .where('created_at >= :start_date', :start_date => start_date)
        .order('event_count desc')
        .limit(num_workspaces)
      .map(&:workspace_id)

      # Get event counts grouped by day and workspace
      events_by_day_workspace = Events::Base
        .group(:workspace_id, "date_trunc('day', created_at)")
        .where('workspace_id IN (:workspace_ids)', :workspace_ids => top_workspace_ids)
        .where('created_at >= :start_date', :start_date => start_date)
      .count

      # Fill in gaps
      (0..num_days).each do |d|
        top_workspace_ids.each do |id|
          events_by_day_workspace[[id, d.days.ago.strftime('%F 00:00:00')]] ||= 0
        end
      end

      # Sort by date
      events_by_day_workspace = events_by_day_workspace.sort_by { |k,v| Date.strptime(k.last, '%F %T') }

      # Put into json structure expected by d3 frontend js
      res = events_by_day_workspace.map do |t, v|
        {date_part: t.last,
         workspace_id: t.first,
         event_count: v,
         rank: top_workspace_ids.find_index(t.first)}
      end

      res
    end
  end
end
