require 'factory_girl'

FactoryGirl.define do
  factory :event, :class => Events::Base do
    actor

    factory :greenplum_instance_created_event, :class => Events::GreenplumInstanceCreated do
      gpdb_data_source
    end

    factory :hadoop_instance_created_event, :class => Events::HadoopInstanceCreated do
      hadoop_instance
    end

    factory :greenplum_instance_changed_owner_event, :class => Events::GreenplumInstanceChangedOwner do
      gpdb_data_source
      new_owner :factory => :user
    end

    factory :greenplum_instance_changed_name_event, :class => Events::GreenplumInstanceChangedName do
      gpdb_data_source
      new_name 'new_instance_name'
      old_name 'old_instance_name'
    end

    factory :hadoop_instance_changed_name_event, :class => Events::HadoopInstanceChangedName do
      hadoop_instance
      new_name 'new_instance_name'
      old_name 'old_instance_name'
    end

    factory :workfile_created_event, :class => Events::WorkfileCreated do
      workfile { FactoryGirl.create(:workfile_version).workfile }
      workspace
    end

    factory :source_table_created_event, :class => Events::SourceTableCreated do
      association :dataset, :factory => :gpdb_table
      workspace
    end

    factory :user_created_event, :class => Events::UserAdded do
      association :new_user, :factory => :user
    end

    factory :sandbox_added_event, :class => Events::WorkspaceAddSandbox do
      workspace
    end

    factory :hdfs_external_table_created_event, :class => Events::HdfsFileExtTableCreated do
      association :dataset, :factory => :gpdb_table
      association :hdfs_file, :factory => :hdfs_entry
      workspace
    end

    factory :note_on_greenplum_instance_event, :class => Events::NoteOnGreenplumInstance do
      gpdb_data_source
      body 'Note to self, add a body'
    end

    factory :note_on_hadoop_instance_event, :class => Events::NoteOnHadoopInstance do
      hadoop_instance
      body 'Note to self, add a body'
    end

    factory :note_on_hdfs_file_event, :class => Events::NoteOnHdfsFile do
      association :hdfs_file, :factory => :hdfs_entry
      body 'This is a note on an hdfs file'
    end

    factory :note_on_workspace_event, :class => Events::NoteOnWorkspace do
      association :workspace, :factory => :workspace
      body 'This is a note on a workspace'
    end

    factory :dataset_import_created_event, :class => Events::DatasetImportCreated do
      association :source_dataset, :factory => :gpdb_table
      destination_table 'new_table_for_import'
      workspace
    end
  end
end
