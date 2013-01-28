class CommentMigrator < AbstractMigrator
  class << self
    def prerequisites(options)
      InOrderEventMigrator.migrate(options)
    end

    def migrate(options={})
      prerequisites(options)

      migrate_comments_on_type("comment")
      migrate_comments_on_type("activity_stream")
    end

    def migrate_comments_on_type(entity_type)
      Legacy.connection.exec_query(<<-SQL)
      INSERT INTO comments(
        legacy_id,
        body,
        event_id,
        author_id,
        created_at,
        updated_at,
        deleted_at
        )
      SELECT
        edc_comment.id,
        body,
        events.id,
        (SELECT users.id FROM users WHERE users.username = edc_comment.author_name ORDER BY users.legacy_id DESC limit 1),
        edc_comment.created_stamp AT TIME ZONE 'UTC',
        edc_comment.last_updated_stamp AT TIME ZONE 'UTC',
        CASE edc_comment.is_deleted
          WHEN 't' THEN edc_comment.last_updated_stamp AT TIME ZONE 'UTC'
          ELSE null
        END
      FROM
        edc_comment
        INNER JOIN events
          ON events.legacy_id = edc_comment.entity_id
          AND events.legacy_type = 'edc_#{entity_type}'
      WHERE
        edc_comment.entity_type = '#{entity_type.gsub("_", "")}'
        AND edc_comment.id NOT IN (SELECT legacy_id from comments);
      SQL
    end
  end
end