require 'spec_helper'

describe Workfile do
  it_behaves_like "a notable model" do
    let!(:note) do
      Events::NoteOnWorkfile.create!({
          :actor => users(:owner),
          :workfile => model,
          :body => "This is the body"
      }, :as => :create)
    end

    let!(:model) { FactoryGirl.create(:workfile) }
  end

  describe "validations" do
    it { should validate_presence_of :file_name }
    it { should validate_presence_of :workspace }
    it { should validate_presence_of :owner }

    context "normalize the file name" do
      let!(:another_workfile) { FactoryGirl.create(:workfile, :file_name => 'workfile.sql') }
      let(:workfile) { Workfile.new(:file_name => "workfile.sql") }
      let(:workspace) { another_workfile.workspace }
      let(:resolve_name_conflicts) { false }

      before do
        workfile.resolve_name_conflicts = resolve_name_conflicts
        workfile.workspace = another_workfile.workspace
        workfile.owner = another_workfile.owner
      end

      context "when not resolving name conflicts" do
        it "is not valid" do
          workfile.should_not be_valid
          workfile.file_name.should == "workfile.sql"
        end
      end

      context "first conflict" do
        let(:resolve_name_conflicts) { true }
        it "renames and turns the workfile valid" do
          workfile.should be_valid
          workfile.file_name.should == 'workfile_1.sql'
        end
      end

      context "multiple conflicts" do
        let(:resolve_name_conflicts) { true }
        let!(:another_workfile_2) { FactoryGirl.create(:workfile, :workspace => workspace, :file_name => 'workfile.sql', :resolve_name_conflicts => true) }

        it "increases the name suffix number" do
          workfile.resolve_name_conflicts = true
          workfile.should be_valid
          workfile.file_name.should == 'workfile_2.sql'
        end
      end
    end
  end

  describe ".validate_name_uniqueness" do
    let(:workspace) { workspaces(:public) }
    let(:other_workspace) { workspaces(:private) }
    let(:existing_workfile) { workspace.workfiles.first! }

    it "is invalid if a workfile in the workspace has the same name" do
      new_workfile = FactoryGirl.build(:workfile, :file_name => existing_workfile.file_name, :workspace => workspace)
      new_workfile.validate_name_uniqueness.should be_false
      new_workfile.should have_error_on(:file_name)
    end

    it "is valid if a workfile in another workspace has the same name" do
      new_workfile = FactoryGirl.build(:workfile, :file_name => existing_workfile.file_name, :workspace => other_workspace)
      new_workfile.validate_name_uniqueness.should be_true
    end
  end

  describe "associations" do
    it { should belong_to :owner }
    it { should have_many :activities }
    it { should have_many :events }
    it { should have_many :notes }
    it { should have_many :comments }

    describe "#notes" do
      let(:workfile) { workfiles(:private) }
      let(:author) { workfile.owner }

      it 'returns notes' do
        set_current_user(author)
        note = Events::NoteOnWorkfile.create!({:note_target => workfile, :body => "note on a workfile"}, :as => :create)
        workfile.reload
        workfile.notes.first.should be_a(Events::NoteOnWorkfile)
        workfile.notes.should == [note]
      end
    end

    it "destroys dependent versions" do
      workfile = workfiles(:public)
      versions = workfile.versions
      versions.length.should > 0

      workfile.destroy
      versions.each do |version|
        WorkfileVersion.find_by_id(version.id).should be_nil
      end
    end
  end

  describe "search fields" do
    it "indexes text fields" do
      Workfile.should have_searchable_field :file_name
      Workfile.should have_searchable_field :description
      Workfile.should have_searchable_field :version_comments
    end
  end

  describe "entity_type_name" do
    it "should return 'workfile'" do
      Workfile.new.entity_type_name.should == 'workfile'
    end
  end

  describe "copy" do
    let(:workfile) { workfiles(:public) }
    let(:workspace) { workspaces(:private) }
    let(:user) { users(:admin) }

    it "copies the associated data" do
      new_workfile = workfile.copy(user, workspace)
      new_workfile.file_name = workfile.file_name
      new_workfile.description = workfile.description
      new_workfile.workspace = workspace
      new_workfile.owner = user
    end

    it "copies any additional_data" do
      workfile.additional_data["something"] = "here"
      new_workfile = workfile.copy(user, workspace)
      new_workfile.additional_data["something"].should == "here"
    end
  end

  describe "create" do
    let(:workspace) { workspaces(:empty_workspace) }
    let(:user) { users(:owner) }

    it 'updates has_added_workfile on the workspace to true' do
      workspace.has_added_workfile.should be_false
      Workfile.build_for(:workspace => workspace, :owner => user, :file_name => 'test.sql').save!
      workspace.reload.has_added_workfile.should be_true
    end

    it 'makes a WorkfileCreated event' do
      set_current_user(user)
      description = 'i am a description'
      expect {
        Workfile.build_for(:workspace => workspace, :owner => user, :file_name => 'test.sql', :description => description).save!
      }.to change(Events::WorkfileCreated, :count).by(1)
      event = Events::WorkfileCreated.by(user).last
      event.workfile.description.should == description
      event.additional_data['commit_message'].should == description
      event.workspace.should == workspace
    end

    context 'when file_name is invalid' do
      it 'has a validation error rather than exploding' do
        workfile = Workfile.build_for(:workspace => workspace, :owner => user, :file_name => 'a/test.sql')
        workfile.save
        workfile.should have_error_on(:file_name)
      end
    end

  end

  describe 'user_modified_at' do
    let(:workfile) { workfiles(:public) }

    it 'does not update when adding tags' do
      expect do
        workfile.tag_list=(['garden', 'gnomes'])
      end.not_to change { workfile.user_modified_at }
    end

    it 'does not update when changing execution schema' do
      schema = schemas(:default)
      expect do
        workfile.execution_schema = schema
        workfile.save
      end.not_to change { workfile.user_modified_at }
    end

    it "updates on create" do
      workfile = FactoryGirl.create(:workfile)
      workfile.user_modified_at.should_not be_nil
    end
  end

  it_should_behave_like "taggable models", [:workfiles, :public]

  it_behaves_like 'a soft deletable model' do
    let(:model) { workfiles(:public) }
  end
end
