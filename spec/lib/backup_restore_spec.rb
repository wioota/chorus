require 'spec_helper'
require 'timecop'

require 'backup_restore'
require 'pathname'

describe 'BackupRestore' do
  describe 'Backup' do
    describe ".backup" do
      context "with a fake chorus installation in a temporary directory" do
        let(:backup_path) { Pathname.new "backup_path" }
        let(:rolling_days) { 3 }
        let(:assets) {["users/asset_file.icon"]}

        before do
          any_instance_of(BackupRestore::Backup) do |instance|
            stub(instance).log.with_any_args
          end
        end

        around do |example|
          # create fake install
          make_tmp_path("rspec_backup_install") do |chorus_path|
            @chorus_path = chorus_path
            populate_fake_chorus_install(chorus_path, :assets => assets)

            FileUtils.mkdir_p chorus_path.join(backup_path)

            with_rails_root chorus_path do
              Dir.chdir chorus_path do
                example.call
              end
            end
          end
        end

        def run_backup
          Timecop.freeze do
            Dir.chdir @chorus_path do
              BackupRestore.backup backup_path, rolling_days
              @expected_backup_file = @chorus_path.join backup_path, backup_filename(Time.current)
            end
          end
        end

        it "creates the backup directory if it does not exist" do
          backup_dir = @chorus_path.join backup_path
          FileUtils.rm_rf backup_dir
          Dir.exists?(backup_dir).should be_false
          run_backup
          Dir.exists?(backup_dir).should be_true
        end

        it "creates a backup file with the correct timestamp" do
          run_backup
          @expected_backup_file.should exist
        end

        it "creates only the backup file and leaves no other trace" do
          new_files_created(@chorus_path.join backup_path) do
            run_backup
          end.should == [Pathname.new(@expected_backup_file)]
        end

        it "works even if chorus.properties does not exist" do
          config = Rails.root.join("config/chorus.properties")
          FileUtils.rm config if File.exists?(config)
          expect {
            run_backup
          }.to_not raise_error
        end

        context "when a system command fails" do
          it "cleans up all the files it created" do
            any_instance_of(BackupRestore::Backup) do |instance|
              stub(instance).capture_output.with_any_args { |cmd| raise "you can't do that!" if /tar/ =~ cmd }
            end
            new_files_created(@chorus_path) do
              expect {
                run_backup
              }.to raise_error("you can't do that!")
            end.should == []
          end
        end

        it "requires a positive integer for the number of rolling days" do
          expect {
            BackupRestore.backup backup_path, 0
          }.to raise_error(/positive integer/)
        end

        xit "includes the assets in the backup" do
          run_backup
          asset_list = `tar xfO #{@expected_backup_file} assets_storage_path.tgz | tar t`
          asset_list.split.should include(*assets)
        end

        context "when there are no assets" do
          let(:assets) {[]}

          it "doesn't create the assets file" do
            run_backup
            @expected_backup_file.should exist
            file_list = `tar tf #{@expected_backup_file}`
            file_list.should_not include("assets_storage_path")
          end
        end

        describe "rolling backups: " do
          let(:old_backup) { @chorus_path.join backup_path.join(backup_filename(old_backup_time)) }
          let(:rolling_days) { nil }

          before do
            FileUtils.touch old_backup
            BackupRestore.backup *[backup_path, rolling_days].compact
          end

          context "when rolling days parameter is provided" do

            let(:rolling_days) { 11 }

            context "when the old backup was created more than the stated time ago" do
              let(:old_backup_time) { rolling_days.days.ago - 1.hour }

              it "deletes it" do
                old_backup.should_not exist
              end
            end

            context "when old backup was created within stated time" do
              let(:old_backup_time) { rolling_days.days.ago + 1.hour }

              it "keeps it" do
                old_backup.should exist
              end
            end
          end

          context "when rolling days parameter is not provided" do

            let(:rolling_days) { nil }
            let(:old_backup_time) { 1.year.ago }

            it "does not remove old backups" do
              old_backup.should exist
            end
          end
        end
      end
    end

    def new_files_created(*dirs)
      entries_before_block = all_filesystem_entries(*dirs)
      yield
      all_filesystem_entries(*dirs) - entries_before_block
    end

    def backup_filename(time)
      "greenplum_chorus_backup_" + time.strftime('%Y%m%d_%H%M%S') + ".tar"
    end
  end

  describe 'Restore' do
    self.use_transactional_fixtures = false

    before do
      any_instance_of(BackupRestore::Restore) do |instance|
        stub(instance).log.with_any_args
        stub(instance).restore_database
      end
    end

    describe ".restore" do
      let(:restore_path) { @tmp_path.join "restore" }
      let(:backup_path) { @tmp_path.join "backup" }
      let(:current_version_string) {"0.2.0.0-1d012455"}
      let(:backup_version_string) { current_version_string }
      let(:backup_tar) { backup_path.join "backup.tar" }
      let(:no_chorus_properties) { false }
      let(:no_assets_storage_path) { false }
      let(:old_asset_file) {"users/old_asset_file.icon"}
      let(:assets) {[old_asset_file]}

      around do |example|
        make_tmp_path("rspec_backup_restore") do |tmp_path|
          @tmp_path = tmp_path

          # create a directory to restore to
          Dir.mkdir restore_path
          populate_fake_chorus_install(restore_path, :version => current_version_string, :assets => assets)
          FileUtils.rm_f restore_path.join("config/chorus.properties")

          # create a fake backup in another directory
          Dir.mkdir backup_path and Dir.chdir backup_path do
            create_version_build(backup_version_string)
            system "echo database | gzip > database.sql.gz"
            FileUtils.touch "chorus.properties" unless no_chorus_properties
            FileUtils.touch "sample_asset"
            system "tar czf assets_storage_path.tgz sample_asset > /dev/null"
            FileUtils.rm "sample_asset"
            files = "version_build database.sql.gz"
            files += " assets_storage_path.tgz" unless no_assets_storage_path
            system "tar cf #{backup_tar} #{files}"
          end

          Dir.chdir restore_path do
            with_rails_root restore_path do
              example.call
            end
          end
        end
      end

      it "restores the backed-up data" do
        BackupRestore.restore backup_tar, true
      end

      it "works with relative paths" do
        BackupRestore.restore "../backup/backup.tar", true
      end

      it "removes the old assets" do
        old_asset = asset_path.join old_asset_file
        old_asset.should exist
        BackupRestore.restore "../backup/backup.tar", true
        old_asset.should_not exist
      end

      context "when chorus.properties does not exist" do
        let(:no_chorus_properties) { true }

        it "works without chorus.properties" do
          BackupRestore.restore "../backup/backup.tar", true
        end
      end

      context "when the original backup has no assets" do
        let(:no_assets_storage_path) { true }

        it "still works" do
          BackupRestore.restore "../backup/backup.tar", true
        end

        it "still removes the old assets" do
          old_asset = asset_path.join old_asset_file
          old_asset.should exist
          BackupRestore.restore "../backup/backup.tar", true
          old_asset.should_not exist
        end
      end

      context "when the backup file does not exist" do
        it "raises an exception" do
          capture(:stderr) do
            expect {
              BackupRestore.restore "missing_backup.tar", true
            }.to raise_error "Could not unpack backup file 'missing_backup.tar'"
          end.should include "Could not unpack backup file 'missing_backup.tar'"
        end
      end

      context "when the restore is not run in rails root directory" do
        before do
          sub_dir = restore_path.join 'sub_dir'
          FileUtils.mkdir_p sub_dir
          Dir.chdir sub_dir
        end
      end

      context "when the backup version doesn't match the current version" do
        let(:backup_version_string) { current_version_string + " not!" }

        it "raises an exception" do
          expect {
            BackupRestore.restore backup_tar, true
          }.to raise_error(/differs from installed chorus version/)
        end
      end

      def current_directory_should_be(dir)
        current_dir = Dir.pwd
        Dir.chdir(dir) do
          Dir.pwd.should == current_dir
        end
      end
    end
  end
end

describe "Backup and Restore" do
  include Deployment
  self.use_transactional_fixtures = false

  before do
    any_instance_of(BackupRestore::Backup) do |backup|
      stub(backup).log.with_any_args
    end
    any_instance_of(BackupRestore::Restore) do |restore|
      stub(restore).log.with_any_args
    end
  end

  #after(:all) do
  #  # return the test database to its original state
  #  without_database_connection do
  #    begin
  #      original_rake_application = Rake.application
  #      @rake = Rake::Application.new
  #      Rake.application = @rake
  #      Rake.application.rake_require "backup_and_restore"
  #      Rake::Task.define_task(:environment)
  #      @rake["db:test:prepare"].invoke
  #      @rake["db:fixtures:load"].invoke
  #    ensure
  #      Rake.application = original_rake_application
  #    end
  #  end
  #end

  around do |example|
    # create fake original and restored install
    make_tmp_path("rspec_backup_restore_original") do |original_path|
      make_tmp_path("rspec_backup_restore_restored") do |restore_path|
        @original_path = original_path
        @restore_path = restore_path

        # populate original directory from development tree
        populate_fake_chorus_install @original_path, :assets => ["users/asset_file.icon"]

        # populate restore target with just config directory minus chorus.properties
        populate_fake_chorus_install @restore_path

        # remove chorus.properties file from restore dir so we can replace it later
        FileUtils.rm_f @restore_path.join "config/chorus.properties"

        with_rails_root @original_path do
          example.call
        end
      end
    end
  end

  xit "backs up and restores the data" do
    make_tmp_path("rspec_backup_restore_backup") do |backup_path|
      all_models_before_backup = all_models

      with_rails_root @original_path do
        BackupRestore.backup backup_path
      end

      backup_filename = Dir.glob(backup_path.join "*.tar").first

      deleted_user = User.first.delete

      with_rails_root @restore_path do
        BackupRestore.restore backup_filename, true
      end

      original_entries = get_filesystem_entries_at_path @original_path
      restored_entries = get_filesystem_entries_at_path @restore_path

      restored_entries.should == original_entries

      User.find_by_id(deleted_user.id).should == deleted_user

      all_models.should_not == []
      all_models.should =~ all_models_before_backup
    end
  end

  def all_models
    ActiveRecord::Base.subclasses.map(&:unscoped).flatten.map(&:reload)
  end

  def get_filesystem_entries_at_path(path)
    pathname = Pathname.new(path)
    all_filesystem_entries(path).map do |entry|
      Pathname.new(entry).relative_path_from(pathname).to_s
    end.sort.uniq
  end
end

def with_rails_root(root)
  original_chorus_home = ENV['CHORUS_HOME']
  ENV['CHORUS_HOME'] = root.to_s
  original_rails_root = Rails.root
  Rails.application.config.root = Pathname.new root
  yield
ensure
  ENV['CHORUS_HOME'] = original_chorus_home
  Rails.application.config.root = original_rails_root
end

def create_version_build(version_string)
  File.open "version_build", "w" do |file|
    file.puts version_string
  end
end

def make_tmp_path(*args)
  SafeMktmpdir.mktmpdir *args do |tmp_dir|
    yield Pathname.new tmp_dir
  end
end

def all_filesystem_entries(*paths)
  files = paths.map do |path|
    path = Pathname.new(path)
    files = %w{. **/ **/*}.map do |wildcard|
      Dir.glob path.join wildcard
    end
  end.flatten.sort.uniq

  files.map {|f| Pathname.new(f).realpath}
end

def populate_fake_chorus_install(install_path, options = {})
  version = options[:version] || "0.2.0.0-1d012455"
  assets = options[:assets] || []

  %w{config}.each do |dir|
    FileUtils.cp_r Rails.root.join(dir), install_path
  end

  %w{packaging postgres}.each do |dir|
    path = Rails.root.join(dir)
    path.should exist
    FileUtils.ln_s path, install_path.join(dir)
  end

  # create a fake asset in original
  with_rails_root(install_path) do
    FileUtils.mkdir_p asset_path

    assets.each do |asset|
      FileUtils.mkdir_p asset_path.join(File.dirname(asset))
      FileUtils.touch asset_path.join(asset)
    end
  end

  Dir.chdir install_path do
    create_version_build(version)
  end
end

def without_database_connection
  existing_connection = ActiveRecord::Base.connection_handler.active_connections?
  if existing_connection
    connection_config = ActiveRecord::Base.connection_config
    ActiveRecord::Base.connection.disconnect!
  end
  yield
ensure
  ActiveRecord::Base.establish_connection connection_config if existing_connection
end

def asset_path
  chorus_config = ChorusConfig.new
  Rails.root.join chorus_config['assets_storage_path'].gsub(":rails_root/", "")
end

require 'stringio'

def capture(*streams)
  streams.map! { |stream| stream.to_s }
  begin
    result = StringIO.new
    streams.each { |stream| eval "$#{stream} = result" }
    yield
  ensure
    streams.each { |stream| eval("$#{stream} = #{stream.upcase}") }
  end
  result.string
end
