require 'spec_helper'

describe HdfsDataSource do
  subject { hdfs_data_sources(:hadoop) }

  it_behaves_like "a notable model" do
    let!(:note) do
      Events::NoteOnHdfsDataSource.create!({
        :actor => users(:owner),
        :hdfs_data_source => model,
        :body => "This is the body"
      }, :as => :create)
    end

    let!(:model) { FactoryGirl.create(:hdfs_data_source) }
  end

  describe "associations" do
    it { should belong_to :owner }
    its(:owner) { should be_a User }
    it { should have_many :activities }
    it { should have_many :events }
    it { should have_many :hdfs_entries }
  end

  describe "validations" do
    it { should validate_presence_of :host }
    it { should validate_presence_of :name }
    it { should validate_presence_of :port }

    it_should_behave_like "it validates with DataSourceNameValidator"

    it_should_behave_like 'a model with name validations' do
      let(:factory_name) { :hdfs_data_source }
    end
  end

  describe "destroy" do
    it "enqueues a destroy_entries job" do
      mock(QC.default_queue).enqueue_if_not_queued("HdfsEntry.destroy_entries", subject.id)
      subject.destroy
    end
  end

  describe "#check_status!" do
    let(:data_source) { hdfs_data_sources(:hadoop) }

    context "when the data source is offline" do

      before do
        stub(Hdfs::QueryService).accessible? { false }
        stub(Hdfs::QueryService).version_of.with_any_args { raise ApiValidationError }
        do_not_allow(Hdfs::QueryService).version_of.with_any_args { raise ApiValidationError }
      end

      it "sets the state to offline" do
        data_source.state = "whatever"
        data_source.check_status!
        data_source.state.should == "offline"
      end

      it "updates last_checked_at" do
        expect {
          data_source.check_status!
        }.to change(data_source, :last_checked_at)
      end

      it "does not update last_online_at" do
        expect {
          data_source.check_status!
        }.not_to change(data_source, :last_online_at)
      end
    end

    context "when the data source is online"
    before do
      stub(Hdfs::QueryService).accessible? { true }
      stub(Hdfs::QueryService).version_of.with_any_args { "xyz" }
    end

    it "sets the state to online" do
      data_source.state = "whatever"
      data_source.check_status!
      data_source.state.should == "online"
    end

    it "updates the version" do
      data_source.version = "whatever"
      data_source.check_status!
      data_source.version == "xyz"
    end

    it "updates last_checked_at" do
      expect {
        data_source.check_status!
      }.to change(data_source, :last_checked_at)
    end

    it "updates last_online_at" do
      expect {
        data_source.check_status!
      }.to change(data_source, :last_online_at)
    end
  end

  describe "#refresh" do
    let(:root_file) { HdfsEntry.new({:path => '/foo.txt'}, :without_protection => true) }
    let(:root_dir) { HdfsEntry.new({:path => '/bar', :is_directory => true}, :without_protection => true) }
    let(:deep_dir) { HdfsEntry.new({:path => '/bar/baz', :is_directory => true}, :without_protection => true) }

    it "lists the root directory for the data source" do
      mock(HdfsEntry).list('/', subject) { [root_file, root_dir] }
      mock(HdfsEntry).list(root_dir.path, subject) { [] }
      subject.refresh
    end

    it "recurses through the directory hierarchy" do
      mock(HdfsEntry).list('/', subject) { [root_file, root_dir] }
      mock(HdfsEntry).list(root_dir.path, subject) { [deep_dir] }
      mock(HdfsEntry).list(deep_dir.path, subject) { [] }
      subject.refresh
    end

    context "when the server is not reachable" do
      let(:data_source) { hdfs_data_sources(:hadoop) }
      before do
        any_instance_of(Hdfs::QueryService) do |qs|
          stub(qs).list { raise Hdfs::DirectoryNotFoundError.new("ERROR!") }
        end
      end

      it "marks all the hdfs entries as stale" do
        data_source.refresh
        data_source.hdfs_entries.size.should > 3
        data_source.hdfs_entries.each do |entry|
          entry.should be_stale
        end
      end
    end

    context "when a DirectoryNotFoundError happens on a subdirectory" do
      let(:data_source) { hdfs_data_sources(:hadoop) }
      before do
        any_instance_of(Hdfs::QueryService) do |qs|
          stub(qs).list { raise Hdfs::DirectoryNotFoundError.new("ERROR!") }
        end
      end

      it "does not mark any entries as stale" do
        expect {
          data_source.refresh("/foo")
        }.to_not change { data_source.hdfs_entries.not_stale.count }
      end
    end
  end

  describe "after being created" do
    before do
      @new_data_source = HdfsDataSource.create({:owner => User.first, :name => "Hadoop", :host => "localhost", :port => "8020"}, { :without_protection => true })
    end

    it "creates an HDFS root entry" do
      root_entry = @new_data_source.hdfs_entries.find_by_path("/")
      root_entry.should be_present
      root_entry.is_directory.should be_true
    end
  end

  describe "after being updated" do
    let(:data_source) { HdfsDataSource.first }

    it "it doesn't create any entries" do
      expect {
        data_source.name += "_updated"
        data_source.save!
      }.not_to change(HdfsEntry, :count)
    end
  end

  it_should_behave_like "taggable models", [:hdfs_data_sources, :hadoop]

  it_behaves_like 'a soft deletable model' do
    let(:model) { subject }
  end

end
