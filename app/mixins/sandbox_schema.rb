module SandboxSchema
  extend ActiveSupport::Concern

  included do
    #imports must be cancelled before we nullify the sandbox_id on workspaces
    before_destroy :cancel_imports

    has_many :workspaces, :foreign_key => :sandbox_id, :dependent => :nullify

    has_many :imports, class_name: 'SchemaImport', foreign_key: 'schema_id'
    has_many :imports_via_workspaces, :through => :workspaces, :source => :all_imports

    has_many :workfiles_as_execution_location, :class_name => 'Workfile', :as => :execution_location, :dependent => :nullify
  end

  private

  def cancel_imports
    imports.unfinished.each do |import|
      import.cancel(false, 'Source/Destination of this import was deleted')
    end
    imports_via_workspaces.unfinished.each do |import|
      import.cancel(false, 'Source/Destination of this import was deleted')
    end
  end
end
