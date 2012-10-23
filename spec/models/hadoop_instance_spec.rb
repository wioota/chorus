require 'spec_helper'

describe HadoopInstance do
  subject { FactoryGirl.build :hadoop_instance }

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

    describe "name" do
      context "when hadoop instance name is invalid format" do
        it "fails validation when not a valid format" do
          FactoryGirl.build(:hadoop_instance, :name => "1aaa1").should_not be_valid
        end

        it "fails validation due to field length" do
          FactoryGirl.build(:hadoop_instance, :name => 'a'*65).should_not be_valid
        end

        it "does not fail validation due to field length" do
          FactoryGirl.build(:hadoop_instance, :name => 'a'*45).should be_valid
        end
      end

      context "when hadoop instance name is valid" do
        it "validates" do
          FactoryGirl.build(:hadoop_instance, :name => "aaa1").should be_valid
        end
      end
    end
  end

  describe "#refresh" do
    let(:root_file) { HdfsEntry.new({:path => '/foo.txt'}, :without_protection => true) }
    let(:root_dir) { HdfsEntry.new({:path => '/bar', :is_directory => true}, :without_protection => true) }
    let(:deep_dir) { HdfsEntry.new({:path => '/bar/baz', :is_directory => true}, :without_protection => true) }

    it "lists the root directory for the instance" do
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
      let(:instance) { hadoop_instances(:hadoop) }
      before do
        any_instance_of(Hdfs::QueryService) do |qs|
          stub(qs).list { raise Hdfs::DirectoryNotFoundError.new("ERROR!") }
        end
      end

      it "marks all the hdfs entries as stale" do
        instance.refresh
        instance.hdfs_entries.size.should > 3
        instance.hdfs_entries.each do |entry|
          entry.should be_stale
        end
      end
    end

    context "when a DirectoryNotFoundError happens on a subdirectory" do
      let(:instance) { hadoop_instances(:hadoop) }
      before do
        any_instance_of(Hdfs::QueryService) do |qs|
          stub(qs).list { raise Hdfs::DirectoryNotFoundError.new("ERROR!") }
        end
      end

      it "does not mark any entries as stale" do
        expect {
          instance.refresh("/foo")
        }.to_not change { instance.hdfs_entries.not_stale.count }
      end
    end
  end

  describe "after being created" do
    before do
      @new_instance = HadoopInstance.create({:owner => User.first, :name => "Hadoop", :host => "localhost", :port => "8020"}, { :without_protection => true })
    end

    it "creates an HDFS root entry" do
      root_entry = @new_instance.hdfs_entries.find_by_path("/")
      root_entry.should be_present
      root_entry.is_directory.should be_true
    end
  end

  describe "after being updated" do
    let(:instance) { HadoopInstance.first }

    it "it doesn't create any entries" do
      expect {
        instance.name += "_updated"
        instance.save!
      }.not_to change(HdfsEntry, :count)
    end
  end
end
