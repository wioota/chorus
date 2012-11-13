require 'legacy_migration_spec_helper'

describe DataMigrator do
  describe ".migrate" do
    it "migrates and validates all without blowing up" do
      mock(InstanceAccountMigrator).migrate.any_number_of_times
      mock(ImageMigrator).migrate.any_number_of_times
      mock(SandboxMigrator).migrate.any_number_of_times
      mock(AssociatedDatasetMigrator).migrate.any_number_of_times
      mock(ImportScheduleMigrator).migrate.any_number_of_times
      mock(ActivityMigrator).migrate.with(anything).any_number_of_times
      mock(NoteMigrator).migrate.with(anything).any_number_of_times
      mock(NotificationMigrator).migrate.with(anything).any_number_of_times

      mock(ActivityMigrator).validate
      mock(AssociatedDatasetMigrator).validate
      mock(DatabaseObjectMigrator).validate
      mock(HadoopInstanceMigrator).validate
      mock(HdfsEntryMigrator).validate
      mock(InstanceAccountMigrator).validate
      mock(GpdbInstanceMigrator).validate
      mock(MembershipMigrator).validate
      mock(ImportScheduleMigrator).validate
      mock(AttachmentMigrator).validate
      mock(NoteMigrator).validate
      mock(NotificationMigrator).validate
      mock(UserMigrator).validate
      mock(WorkfileMigrator).validate
      mock(WorkspaceMigrator).validate

      DataMigrator.migrate_all(SPEC_WORKFILE_PATH)
    end
  end
end
