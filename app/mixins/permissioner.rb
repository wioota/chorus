# Module for dealing with permission bitmasks. It adds class methods
# that generate bitmasks or permission bits using the PERMISSIONS
# constant on the class

module Permissioner
  extend ActiveSupport::Concern

  module ClassMethods

    # Given an activity, this method returns an integer with that
    # bit set
    def bitmask_for(activity_symbol)
      with_permissions_defined do
        index = self::PERMISSIONS.index(activity_symbol)
        raise Allowy::AccessDenied.new("Activity not found", nil, nil) if index.nil?
        return 1 << index
      end
    end

    # Given an array of permission symbols, this function
    # returns an integer with the proper permission bits set
    def create_permission_bits_for(activity_symbol_array)
      with_permissions_defined do
        bits = 0
        return bits if activity_symbol_array.nil?

        activity_symbol_array.each do |activity_symbol|
          index = self::PERMISSIONS.index(activity_symbol)
          bits |= ( 1 << index )
        end

        return bits
      end
    end

    # DataSource.create_permissions_for dev_role, [:edit]
    def create_permissions_for(roles, activity_symbol_array)
      klass = self
      roles, activities = Array.wrap(roles), Array.wrap(activity_symbol_array)
      chorus_class = ChorusClass.find_or_create_by_name(self.name)

      permissions = roles.map do |role|
        permission = Permission.find_or_initialize_by_role_id_and_chorus_class_id(role.id, chorus_class.id)

        # NOTE: This currently over-writes the permissions mask. It would be useful to have
        # (create, add, remove), or, (create, modify) with options
        permission.permissions_mask = klass.create_permission_bits_for(activities)
        permission.role = role
        permission
      end

      chorus_class.permissions << permissions
    end

    # Figure out how to make these private
    def with_permissions_defined
      if const_defined? 'PERMISSIONS'
        yield
      else
        permissions_not_defined
      end
    end

    def permissions_not_defined
      Chorus.log_debug("PERMISSIONS are not defined on #{self.name} model")
      puts "PERMISSIONS are not defined on #{self.name} model"
      # raise different error, this one doesn't really make sense
      raise Allowy::AccessDenied.new("PERMISSIONS are not defined on #{self.name} model", nil, nil)
    end

  end # ClassMethods
end