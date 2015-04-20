# This class holds code that deals with adding/removing users from a workspace
# and any cleanup/ownership transfers associated with that change
class WorkspaceMembersManager

  # roles_ids hash looks like { :member => [id1, id2], :manager => [id3, id4] }
  def initialize(workspace, roles_ids, acting_user)
    @workspace = workspace
    @roles_ids = roles_ids
    @acting_user = acting_user
  end

  def update_membership
    workspace_current_members = @workspace.members.map(&:id)
    new_members = @roles_ids.values.flatten.map(&:to_i) - workspace_current_members
    removed_member_ids = workspace_current_members - @roles_ids.values.flatten.map(&:to_i)
    @roles_ids.each{ |k,v| v.map!(&:to_i) }

    @workspace.transaction do
      add_members_with_roles(new_members)

      removed_members = removed_member_ids.map{ |id| User.find(id) }
      @workspace.members.delete(removed_members)

      @workspace.update_attributes!(:has_added_member => true)
      transfer_job_ownership(removed_member_ids)
    end

    create_events(new_members)
    @workspace.solr_reindex_later
  end

  private

  def add_members_with_roles(new_members)
    @roles_ids.each do |role, ids|
      new_ids = ids & new_members
      new_ids.each do |id|
        m = @workspace.memberships.new(:role => role)
        m.user = User.find(id)
        m.save!
      end
    end
  end

  def transfer_job_ownership(removed_member_ids)
    Job.where(:workspace_id => @workspace.id, :owner_id => removed_member_ids).each(&:reset_ownership!)
  end

  def create_events(new_members)
    unless new_members.empty?
      member = User.find(new_members.first)
      num_added = new_members.count
      member_added_event = Events::MembersAdded.by(@acting_user).add(:workspace => @workspace, :member => member, :num_added => num_added)
      new_members.each do |new_member_id|
        Notification.create!(:recipient_id => new_member_id.to_i, :event_id => member_added_event.id)
      end
    end
  end
end
