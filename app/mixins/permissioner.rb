# Module for dealing with permission bitmasks. It adds class methods
# that generate bitmasks or permission bits using the PERMISSIONS
# constant on the class

module Permissioner
  extend ActiveSupport::Concern

  module ClassMethods

    # Given an activity, this method returns an integer with that
    # bit set
    def bitmask_for(activity_symbol)
      if const_defined? 'PERMISSIONS'
        index = self::PERMISSIONS.index(activity_symbol)
        raise Allowy::AccessDenied.new("Activity not found", nil, nil) if index.nil?
        return 1 << index
      else
        permissions_not_defined
      end
    end


    # Given an array of permission symbols, this function
    # returns an integer with the proper permission bits set
    def create_permission_bits_for(activity_symbol_array)
      if const_defined? 'PERMISSIONS'
        bits = 0

        return bits if activity_symbol_array.nil?

        activity_symbol_array.each do |activity_symbol|
          index = self::PERMISSIONS.index(activity_symbol)
          bits |= ( 1 << index )
        end

        return bits
      else
        permissions_not_defined
      end
    end

  end

  def permissions_not_defined
    Chorus.log_debug("PERMISSIONS are not defined on #{self.name} model")
    raise Allowy::AccessDenied.new("PERMISSIONS are not defined on #{self.name} model", nil, nil)
  end
end