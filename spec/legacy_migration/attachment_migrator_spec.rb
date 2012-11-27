require 'legacy_migration_spec_helper'

describe AttachmentMigrator do
  describe ".migrate" do
    it "should migrate the Workfile Attachments on Notes to the new database" do
      count = 0
      Legacy.connection.select_all("
        SELECT eca.*
        FROM edc_comment ec
          INNER JOIN edc_comment_artifact eca
            ON eca.comment_id = ec.id AND eca.entity_type = 'workfile'
      ").each do |legacy_attachment|
        count += 1
        note = Events::Note.find_with_destroyed(:last, :conditions => {:legacy_id => legacy_attachment["comment_id"]})
        workfile = Workfile.find_by_legacy_id(legacy_attachment["entity_id"])
        note.workfiles.should include(workfile)
      end
      count.should > 0
      Legacy.connection.select_all("select count(*) from notes_workfiles").first["count"].should == count
    end

    it "should migrate the dataset Attachments on Notes to the new database" do
      count = 0
      Legacy.connection.select_all("
        SELECT eca.comment_id as comment_id , normalize_key(eca.entity_id) as dataset_id
        FROM edc_comment ec
          INNER JOIN edc_comment_artifact eca
            ON eca.comment_id = ec.id AND eca.entity_type = 'databaseObject'
      ").each do |legacy_attachment|
        count += 1
        note = Events::Note.find_with_destroyed(:last, :conditions => {:legacy_id => legacy_attachment["comment_id"]})
        dataset = Dataset.find_by_legacy_id((legacy_attachment["dataset_id"]))
        note.datasets.should include(dataset)
      end
      count.should > 0
      Legacy.connection.select_all("select count(*) from datasets_notes").first["count"].should == count
    end

    it "migrates all note file attachments" do
      Legacy.connection.select_all("
        SELECT eca.id as attachment_id , ef.file file,
        ef.file_name FROM edc_file ef, edc_comment ec, edc_comment_artifact eca
        WHERE eca.entity_type = 'file' AND eca.comment_id = ec.id AND ef.id = eca.entity_id
      ").each do |legacy_attachment|

        attachment = Attachment.find_by_legacy_id(legacy_attachment["attachment_id"])
        if attachment
          attachment.contents_file_name.should == legacy_attachment["file_name"].gsub(" ", "_")
          File.open(attachment.contents.path, 'r').read == legacy_attachment["file"]
        end
      end
    end

    describe "checking idempotency" do
      before :all do
        @workfile_count = Legacy.connection.select_all("select count(*) from notes_workfiles").first["count"]
        @dataset_count = Legacy.connection.select_all("select count(*) from datasets_notes").first["count"]
        @attachment_count = Legacy.connection.select_all("select count(*) from attachments").first["count"]
        AttachmentMigrator.migrate(:workfile_path => SPEC_WORKFILE_PATH)
      end

      it "is idempotent for workfiles" do
        after_migration_count = Legacy.connection.select_all("select count(*) from notes_workfiles").first["count"]
        after_migration_count.should == @workfile_count
      end

      it "is idempotent for datasets" do
        after_migration_count = Legacy.connection.select_all("select count(*) from datasets_notes").first["count"]
        after_migration_count.should == @dataset_count
      end

      it "is idempotent for desktop attachments" do
        after_migration_count = Legacy.connection.select_all("select count(*) from attachments").first["count"]
        after_migration_count.should == @attachment_count
      end
    end

    it "migrates all the desktop attachments" do
      count = Legacy.connection.select_all("select count(*) from attachments").first
      Legacy.connection.select_all("
        SELECT count(*) as count
        FROM edc_comment_artifact
        WHERE entity_type = 'file'
      ").first["count"].should == count["count"]
    end
  end
end
