module Events
  class JobSucceeded < Base
    has_targets :job, :workspace, :job_result
    has_activities :actor, :job, :workspace

    after_create :notify_workspace_members

    def notify_workspace_members
      workspace.members.each do |user|
        Notification.create!(:recipient_id => user.id, :event_id => self.id)
      end
    end
  end
end