class InstanceAccountPermission < ActiveRecord::Base
  belongs_to :instance_account
  belongs_to :accessed, polymorphic: true

  validate :accessed, presence: true
  validate :instance_account, presence: true
end