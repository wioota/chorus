#
# This class is the prototype utility class that enforces access control.
# It consults the Roles, Groups, and Permissions tables to determine
# a user's abilities to view/modify objects in Chorus. It currently
# provides static methods and does not need to be instantiated.
#

class TempAuthority

  # Attempts to match the given activity with the activities
  # allowed by the user's roles. Raises an Allowy::AccessDenied
  # exception for backwards compatibility
  #
  # 'authorize' finds the permissions for each role the user has
  # on the given class. If a role permission matches the class
  # permission, then the user is authorized for that activity
  def self.authorize!(user, object, activity_symbol)
    roles = retrieve_roles(user)
    chorus_class = ChorusClass.find_by_name(object.class.name)

    actual_class = chorus_class.name.constantize

    common_permissions = common_permissions_between roles, chorus_class

    Chorus.log_debug("Could not find activity_symbol in #{actual_class.name} permissions") if actual_class.PERMISSIONS.index(activity_symbol).nil?

    permission_int = actual_class.PERMISSIONS_INTS[actual_class.PERMISSIONS.index(activity_symbol)]

    allowed = common_permissions.any? do |permission|
      # TODO: Put in bitmask module
      permission.permissions_mask & permission_int == permission_int
    end

    raise Allowy::AccessDenied.new("Unauthorized", activity_symbol, object) unless allowed
  end

  private

  def self.retrieve_roles(user)
    roles = user.roles
    user.groups.each do |group|
      roles << g.roles
    end
    roles
  end

  def self.common_permissions_between(roles, chorus_class)
    all_roles_permissions = roles.inject([]){ |permissions, role| permissions.concat(role.permissions) }
    if chorus_class.permissions.empty? || all_roles_permissions.empty?
      Chorus.log_debug("ChorusClass #{chorus_class} does not haver permissions assigned") if chorus_class.permissions.empty?
      Chorus.log_debug("User.roles and group.roles have no permissions assigned") if all_roles_permissions.empty?
      raise Allowy::AccessDenied.new("Role not found", nil, nil)
    end
    common_permissions = all_roles_permissions & chorus_class.permissions
  end

end