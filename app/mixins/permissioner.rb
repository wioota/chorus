# Module for dealing with permission bitmasks. It adds class methods
# that generate bitmasks or permission bits using the PERMISSIONS
# constant on the class

module Permissioner
  extend ActiveSupport::Concern

  included do
    after_create :initialize_default_roles, :if => Proc.new { |obj| obj.class.const_defined? 'OBJECT_LEVEL_ROLES' }
  end

  module InstanceMethods

    def initialize_default_roles
      default_roles = self.class::OBJECT_LEVEL_ROLES.map do |role_symbol|
        Role.create(:name => role_symbol.to_s)
      end
      object_roles << default_roles
    end

    # Ex: Workspace.first.create_permisisons_for(roles, [:edit, :destroy])
    def add_permissions_for(roles, activity_symbol_array)
      permissions = self.class.generate_permissions_for roles, activity_symbol_array
    end

    def object_roles
      self.save! if new_record?
      chorus_class = ChorusClass.find_or_create_by_name(self.class.name)
      chorus_object = ChorusObject.find_or_create_by_chorus_class_id_and_instance_id(chorus_class.id, self.id)

      chorus_object.roles
    end
  end

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
    def generate_permissions_for(roles, activity_symbol_array)
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

      permissions
    end

    def add_permissions_for(roles, activity_symbol_array)
      chorus_class = ChorusClass.find_or_create_by_name(self.name)
      chorus_class.permissions << generate_permissions_for(roles, activity_symbol_array)
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