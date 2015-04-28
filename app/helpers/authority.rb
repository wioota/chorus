#
# This class is the prototype utility class that enforces access control.
# It consults the Roles, Groups, and Permissions tables to determine
# a user's abilities to view/modify objects in Chorus. It currently
# provides static methods and does not need to be instantiated.
#

module Authority

  # Attempts to match the given activity with the activities
  # allowed by the user's roles. Raises an Allowy::AccessDenied
  # exception for backwards compatibility
  #
  # 'authorize' finds the permissions for each role the user has
  # on the given class. If a role permission matches the class
  # permission, then the user is authorized for that activity
  def self.authorize!(activity_symbol, object, user, options = {})

    # retreive user and object information
    roles = retrieve_roles(user)
    chorus_class = ChorusClass.search_permission_tree(object.class)
    chorus_object = ChorusObject.find_by_chorus_class_id_and_instance_id(chorus_class.id, object.id)
    actual_class = object.class.name.constantize

    # check to see if object and user share scope. Ideally an object and user in different scopes shouldn't even
    # get to this check, because they cannot interact with an object they can't see


    # Is user owner of object?
    #return if is_owner?(user, object) || handle_legacy_action(options[:or], object, user)
    #return if chorus_object.owner == user

    # retreive and merge permissions
    class_permissions = common_permissions_between(roles, chorus_class)
    object_permissions = common_permissions_between(roles, chorus_object)
    permissions = [class_permissions, object_permissions].flatten.compact

    raise Allowy::AccessDenied.new("Unauthorized", activity_symbol, object) unless permissions

    Chorus.log_debug("Could not find activity_symbol in #{actual_class.name} permissions") if actual_class::PERMISSIONS.index(activity_symbol).nil?

    activity_mask = actual_class.bitmask_for(activity_symbol)

    # check to see if this user is allowed to do this action at the object or class level
    allowed = permissions.any? do |permission|
      bit_enabled? permission.permissions_mask, activity_mask
    end

    raise Allowy::AccessDenied.new("Unauthorized", activity_symbol, object) unless allowed
  end

  private

  # This handles legacy authentication actions that are not role-based...
  # Ideally we can get rid of this when Workspace ''roles'' are implemented...
  # Basically just a big case switch
  def self.handle_legacy_action(actions, object, user)
    actions = Array.wrap(actions)
    allowed = false

    actions.each do |action|
      allowed ||= case action
                    when :current_user_is_workspace_owner
                      object.is_a?(::Events::NoteOnWorkspace) && (user == object.workspace.owner)
                    when :current_user_is_in_workspace
                      object.is_a?(::Workspace) && object.member?(user)
                    else
                      false
                    end
    end
    allowed
  end

  # Most things use the owner association, but some (Notes, Events) use actor
  def self.is_owner?(user, object)
    if object.respond_to? :owner
      object.owner == user
    elsif object.respond_to? :actor
      object.actor == user
    else
      return false
    end
  end
  
  def self.retrieve_roles(user)
    roles = user.roles.clone
    user.groups.each do |group|
      roles << g.roles
    end
    roles
  end

  # returns the intersection of all permissions from roles and all permissions for the class
  def self.common_permissions_between(roles, chorus_class_or_object)
    all_roles_permissions = roles.inject([]){ |permissions, role| permissions.concat(role.permissions) }
    if chorus_class_or_object.nil? || chorus_class_or_object.permissions.empty? || all_roles_permissions.empty?
      return nil
    end
    common_permissions = all_roles_permissions & chorus_class_or_object.permissions
  end

  def self.bit_enabled?(bits, mask)
    (bits & mask) == mask
  end

end