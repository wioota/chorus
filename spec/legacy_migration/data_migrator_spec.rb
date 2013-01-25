require 'legacy_migration_spec_helper'

describe DataMigrator do
  describe ".migrate" do
    before do
      mock(InstanceAccountMigrator).migrate.at_least(1)
      mock(ImageMigrator).migrate.at_least(1)
      mock(SandboxMigrator).migrate.at_least(1)
      mock(AssociatedDatasetMigrator).migrate.at_least(1)
      mock(ImportScheduleMigrator).migrate.at_least(1)
      mock(ImportMigrator).migrate.at_least(1)
      mock(ActivityMigrator).migrate.with(anything).at_least(1)
      mock(NoteMigrator).migrate.with(anything).at_least(1)
      mock(NotificationMigrator).migrate.with(anything).at_least(1)

      mock(ActivityMigrator).validate
      mock(AssociatedDatasetMigrator).validate
      mock(DatabaseObjectMigrator).validate
      mock(HadoopInstanceMigrator).validate
      mock(HdfsEntryMigrator).validate
      mock(InstanceAccountMigrator).validate
      mock(GpdbInstanceMigrator).validate
      mock(MembershipMigrator).validate
      mock(AttachmentMigrator).validate
      mock(NoteMigrator).validate
      mock(NotificationMigrator).validate
      mock(UserMigrator).validate
      mock(WorkfileMigrator).validate
      mock(WorkspaceMigrator).validate
    end

    it "migrates and validates all without blowing up" do
      DataMigrator.migrate_all(SPEC_WORKFILE_PATH)
    end

    it "finishes then raises when a validation error occurs after migration" do
      stub(AbstractMigrator).failed? { true }
      expect {
        DataMigrator.migrate_all(SPEC_WORKFILE_PATH)
      }.to raise_error AbstractMigrator::MigratorValidationError, "WARNING: Validation failed. See list of invalid records."
    end
  end
end
