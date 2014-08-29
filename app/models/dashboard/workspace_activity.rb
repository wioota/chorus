module Dashboard
  class WorkspaceActivity < DataModule

    def fetch_results
      Events::Base.connection.execute(<<-SQL)
WITH last_month_weeks AS (
  select date_trunc('week', (current_timestamp - interval '3 week')) as week_part
  UNION
  select date_trunc('week', (current_timestamp - interval '2 week')) as week_part
  UNION
  select date_trunc('week', (current_timestamp - interval '1 week')) as week_part
  UNION
  select date_trunc('week', current_timestamp) as week_part
), last_month_top_workspaces AS (
  SELECT count(*) as event_count, workspace_id
  FROM events
  WHERE (
    deleted_at IS NULL
    AND workspace_id IS NOT NULL
    AND created_at > (current_timestamp - interval '4 week')
  )
  GROUP BY workspace_id
  ORDER BY event_count DESC
  LIMIT 10
), full_list AS (
  SELECT workspace_id, week_part FROM last_month_top_workspaces CROSS JOIN last_month_weeks
), last_month_events AS (
  SELECT workspace_id, date_trunc('week', created_at) AS date_trunc_week_created_at
  FROM events
  WHERE (
    deleted_at IS NULL
    AND workspace_id IS NOT NULL
    AND created_at > (current_timestamp - interval '4 week')
  )
), joined AS (
  SELECT full_list.workspace_id, count(last_month_events.workspace_id) AS event_count, full_list.week_part
  FROM
  full_list
  LEFT JOIN last_month_events
    ON last_month_events.workspace_id = full_list.workspace_id
    AND last_month_events.date_trunc_week_created_at = full_list.week_part
  GROUP BY full_list.workspace_id, full_list.week_part
)
SELECT * FROM joined order by week_part asc, workspace_id;
      SQL
    end

  end
end
