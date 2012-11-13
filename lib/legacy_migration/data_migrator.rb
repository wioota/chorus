class DataMigrator

  # Only need to call the leaf nodes
  def self.migrate_all(workfile_path)
    options = {'workfile_path' => workfile_path}

    InstanceAccountMigrator.migrate
    ImageMigrator.migrate
    SandboxMigrator.migrate
    AssociatedDatasetMigrator.migrate
    ImportScheduleMigrator.migrate
    ImportMigrator.migrate
    AttachmentMigrator.migrate(options)
    NotificationMigrator.migrate(options)

    # Note attachments
    # Note comments

    # Chorus Views
    # Imports

    ActivityMigrator.validate
    AssociatedDatasetMigrator.validate
    DatabaseObjectMigrator.validate
    HadoopInstanceMigrator.validate
    HdfsEntryMigrator.validate
    InstanceAccountMigrator.validate
    GpdbInstanceMigrator.validate
    MembershipMigrator.validate
    ImportScheduleMigrator.validate
    AttachmentMigrator.validate
    NoteMigrator.validate
    NotificationMigrator.validate
    UserMigrator.validate
    WorkfileMigrator.validate
    WorkspaceMigrator.validate
  end
end
