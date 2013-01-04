require 'legacy_migration_spec_helper'

describe CommentMigrator do
  describe ".migrate" do
    it "migrates comments on notes" do
      rows = Legacy.connection.select_all(<<-SQL)
        SELECT ec.*
        FROM edc_comment ec
          INNER JOIN edc_user eu
            ON ec.author_name = eu.user_name
        WHERE entity_type = 'comment'
      SQL
      rows.each do |legacy_comment|
        comment = Comment.find_with_destroyed(:first, :conditions => { :legacy_id => legacy_comment["id"]} )
        comment.body.should == legacy_comment["body"]
        comment.event_id.should == Events::Base.find_with_destroyed(:last, :conditions => { :legacy_id => legacy_comment["entity_id"], :legacy_type => "edc_comment" }).id
        comment.author_id.should == User.find_with_destroyed(:first, :conditions => {:username => legacy_comment["author_name"]}).id
        comment.created_at.should == legacy_comment["created_stamp"]
        comment.updated_at.should == legacy_comment["last_updated_stamp"]
        comment.deleted_at.should == legacy_comment["last_updated_stamp"] if legacy_comment["is_deleted"] == 't'
      end
      rows.length.should > 0
    end

    it "migrates comments on system generated activities" do
      rows = Legacy.connection.select_all(<<-SQL)
        SELECT ec.*
        FROM edc_comment ec
          INNER JOIN edc_user eu
            ON ec.author_name = eu.user_name
          LEFT JOIN edc_activity_stream eas ON ec.entity_id = eas.id
        WHERE ec.entity_type = 'activitystream' AND eas.type NOT IN ('START_PROVISIONING', 'PROVISIONING_SUCCESS', 'PROVISIONING_FAIL')
      SQL
      rows.each do |legacy_comment|
        comment = Comment.find_with_destroyed(:first, :conditions => {:legacy_id => legacy_comment["id"]})
        comment.body.should == legacy_comment["body"]
        comment.event_id.should == Events::Base.find_with_destroyed(:last, :conditions => { :legacy_id => legacy_comment["entity_id"], :legacy_type => "edc_activity_stream" }).id
        comment.author_id.should == User.find_with_destroyed(:first, :conditions => {:username => legacy_comment["author_name"]}).id
        comment.created_at.should == legacy_comment["created_stamp"]
        comment.updated_at.should == legacy_comment["last_updated_stamp"]
        comment.deleted_at.should == legacy_comment["last_updated_stamp"] if legacy_comment["is_deleted"] == 't'
      end
      rows.length.should > 0
    end

    it "has all the comments" do
      rows = Legacy.connection.select_all(<<-SQL)
      SELECT *
        FROM edc_comment ec
        LEFT JOIN edc_activity_stream eas ON ec.entity_id = eas.id
        WHERE ec.entity_type = 'comment'
        OR ec.entity_type = 'activitystream' AND eas.type NOT IN ('START_PROVISIONING', 'PROVISIONING_SUCCESS', 'PROVISIONING_FAIL')
      SQL
      Comment.find_with_destroyed(:all).count.should == rows.length
    end

    it "is idempotent" do
      count = Comment.unscoped.count
      CommentMigrator.migrate(:workfile_path => SPEC_WORKFILE_PATH)
      Comment.unscoped.count.should == count
    end
  end
end

