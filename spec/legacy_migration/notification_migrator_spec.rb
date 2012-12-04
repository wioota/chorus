require 'legacy_migration_spec_helper'

describe NotificationMigrator do
  NOTIFICATION_TYPES = %w{NOTE MEMBERS_ADDED NOTE_COMMENT IMPORT_SUCCESS IMPORT_FAILED}
  NOTIFICATION_TYPES_SQL = NOTIFICATION_TYPES.map {|t| "'#{t}'"}.join ","

  describe ".migrate" do
    it "creates new notifications for legacy notifications" do
      rows = Legacy.connection.select_all(<<-SQL)
        SELECT ea.*
        FROM edc_alert ea
        WHERE type IN (#{NOTIFICATION_TYPES_SQL});
      SQL

      rows.each do |legacy_alert|
        notification = Notification.unscoped.find_by_legacy_id(legacy_alert["id"])

        unless notification
          legacy_ids_with_missing_import_failed_events.should include legacy_alert["id"]
          next
        end

        recipient = User.find(notification.recipient_id)
        recipient.legacy_id.should == legacy_alert["recipient"]

        notification.created_at.should == legacy_alert["created_stamp"]
        notification.updated_at.should == legacy_alert["last_updated_stamp"]
        notification.read.should == (legacy_alert["is_read"] == 't' ? true : false)

        if legacy_alert["is_deleted"] == "t"
          notification.deleted_at.should_not be_nil
        else
          notification.deleted_at.should be_nil
        end
      end

      rows.count.should == Notification.unscoped.count + legacy_ids_with_missing_import_failed_events.count
    end

    it "is idempotent" do
      expect {
        NotificationMigrator.migrate(:workfile_path => SPEC_WORKFILE_PATH)
      }.not_to change(Notification.unscoped, :count)
    end

    it "migrates the notes" do
      rows = Legacy.connection.select_all(<<-SQL)
        SELECT ea.*
        FROM edc_alert ea
        WHERE type = 'NOTE';
      SQL

      rows.each do |legacy_alert|
        notification = Notification.unscoped.find_by_legacy_id(legacy_alert["id"])
        event = Events::Base.find(notification.event_id)
        event.legacy_id.should == legacy_alert["reference"]
      end

      rows.count.should > 0

      notes = Notification.unscoped.where(:comment_id => nil).select do |notification|
        notification.event.legacy_type == 'edc_comment'
      end

      rows.count.should == notes.count
    end

    it "migrates the note_comments" do
      rows = Legacy.connection.select_all(<<-SQL)
        SELECT ea.*
        FROM edc_alert ea
        WHERE type = 'NOTE_COMMENT';
      SQL

      rows.each do |legacy_alert|
        notification = Notification.unscoped.find_by_legacy_id(legacy_alert["id"])

        comment = Comment.unscoped.find(notification.comment_id)
        event = Events::Base.find(notification.event_id)
        comment.legacy_id.should == legacy_alert["reference"]
        event.should == comment.event
      end

      rows.count.should > 0

      Notification.unscoped.where("comment_id is not null").count.should == rows.count
    end

    it "migrates the notification for MEMBERS_ADDED to a workspace" do
      rows = Legacy.connection.select_all(<<-SQL)
        SELECT ea.*
        FROM edc_alert ea
        WHERE type = 'MEMBERS_ADDED';
      SQL

      rows.each do |legacy_alert|
        notification = Notification.unscoped.find_by_legacy_id(legacy_alert["id"])
        event = Events::Base.find(notification.event_id)
        event.workspace_id.should == Workspace.find_by_legacy_id(legacy_alert["reference"]).id
      end

      rows.count.should > 0

      notes = Notification.unscoped.all.select do |notification|
        notification.event.action == 'MembersAdded'
      end
      rows.count.should == notes.count
    end

    it "migrates the notification for IMPORT_SUCCESS AND IMPORT_FAILED" do
      rows = Legacy.connection.select_all(<<-SQL)
        SELECT ea.*, eas.id as event_id
        FROM edc_alert ea
        LEFT JOIN edc_activity_stream_object aso
          ON  aso.object_id = ea.reference AND aso.entity_type = 'import'
        INNER JOIN edc_activity_stream eas
          ON eas.id = aso.activity_stream_id AND eas.type = ea.type
        WHERE ea.type IN ('IMPORT_SUCCESS', 'IMPORT_FAILED');
      SQL

      rows.each do |legacy_alert|
        notification = Notification.unscoped.find_by_legacy_id(legacy_alert["id"])

        recipient = User.find(notification.recipient_id)
        recipient.legacy_id.should == legacy_alert["recipient"]
        notification.event.legacy_id.should == legacy_alert["event_id"]
      end

      rows.count.should > 0

      import_notifications = Notification.unscoped.all.select do |notification|
        notification.event.action =~ /Import(Failed|Success)/
      end

      rows.count.should == import_notifications.count
    end
  end

  def legacy_ids_with_missing_import_failed_events
    @legacy_ids_with_missing_import_failed_events ||=
        Legacy.connection.select_values(<<-SQL)
           SELECT ea.id
           FROM edc_alert ea
           INNER JOIN edc_activity_stream_object aso
             ON aso.object_id = ea.reference AND aso.entity_type = 'import'
           INNER JOIN edc_activity_stream eas
             ON eas.id = aso.activity_stream_id
           GROUP BY ea.id HAVING COUNT(ea.id) = 1;
        SQL
  end
end
