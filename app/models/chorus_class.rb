class ChorusClass < ActiveRecord::Base
  attr_accessible :name, :description, :parent_class_id, :parent_class_name

  has_many :chorus_objects
  has_many :operations
  has_many :permissions

  # Finds the first ancestor with permissions
  # Open to new names, this one isn't great
  def self.search_permission_tree(klass)
    initial_search = find_by_name(klass.name)

    if initial_search.nil?

      superclasses_of(klass).each do |ancestor|
        ancestor_chorus_class = find_by_name(ancestor.to_s)
        return ancestor_chorus_class if ancestor_chorus_class && ancestor_chorus_class.permissions.present?
      end

    else
      return initial_search
    end

    Chorus.log_debug "Couldn't find an ancestor with permissions for the class #{klass}"
    raise Allowy::AccessDenied.new("No permissions found", nil, nil)
    return
  end

  private

  # This nifty method returns an array of classes that are direct superclasses of the given class
  def self.superclasses_of(klass)
    klass.ancestors[1..-1].select{|mod| mod.is_a? Class}
  end
end
