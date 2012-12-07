require 'spec_helper'

describe WorkfilePresenter, :type => :view do
  let(:user) { users(:owner) }
  let(:workfile) { workfiles(:private) }
  let(:workspace) { workfile.workspace }
  let(:options) { {} }
  let(:presenter) { WorkfilePresenter.new(workfile, view, options) }

  before(:each) do
    set_current_user(user)
  end

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    it "includes the right keys" do
      hash.should have_key(:workspace)
      hash.should have_key(:owner)

      hash.should have_key(:file_name)
      hash.should have_key(:file_type)
      hash.should have_key(:latest_version_id)
      hash.should have_key(:has_draft)
      hash.should have_key(:is_deleted)
      hash.should have_key(:recent_comments)
      hash.should have_key(:comment_count)

      hash.should_not have_key(:execution_schema)
    end

    it "uses the workspace presenter to serialize the workspace" do
      hash[:workspace].to_hash.should == (WorkspacePresenter.new(workspace, view).presentation_hash)
    end

    it "uses the user presenter to serialize the owner" do
      hash[:owner].to_hash.should == (UserPresenter.new(user, view).presentation_hash)
    end

    it "uses the workfile file name" do
      hash[:file_name].should == workfile.file_name
    end

    describe "it presents the commit message for a workfile" do
      let(:recent_comments) { hash[:recent_comments] }
      let(:workfile_created_event) {Events::WorkfileCreated.by(user).add(:workfile => workfile, :commit_message => "original version", :workspace => workspace)}

      before do
        workfile.events.clear
        workfile_created_event
      end

      it "presents the commit message" do
        recent_comments[0][:author].to_hash.should == Presenter.present(user, view)
        recent_comments[0][:body].should == "original version"
        recent_comments[0][:timestamp].should == workfile_created_event.created_at
      end

      context "when there's a newer version of a workfile" do
        let(:latest_workfile_version) {
          workfile.versions.create!(:owner => user, :modifier => user).tap do |version|
            workfile.latest_workfile_version = version
          end
        }
        let(:new_workfile_version_event) {
          Timecop.freeze Time.current + 1.day do
            Events::WorkfileUpgradedVersion.by(user).add(:workfile => workfile, :commit_message => "new version", :workspace => workspace, :version_id => latest_workfile_version.id)
          end
        }

        before do
          latest_workfile_version
          new_workfile_version_event
        end

        it "presents the commit message" do
          recent_comments[0][:body].should == "new version"
        end

        context "when there is a note before the newer version" do
          before do
            Events::NoteOnWorkfile.by(user).add(:workspace => workspace, :workfile => workfile, :body => 'note on old version')
          end

          it "still presents the commit message" do
            recent_comments[0][:body].should == "new version"
          end
        end

        context "when the new workfile version has been deleted" do
          before do
            latest_workfile_version.destroy
            workfile.latest_workfile_version_id = nil
          end

          it "presents the original commit message for the workfile" do
            recent_comments[0][:body].should == "original version"
          end
        end
      end
    end

    context "when there are notes on a workfile" do
      let(:recent_comments) { hash[:recent_comments] }
      let(:today) { Time.current }
      let(:yesterday) { today - 1.day }

      before do
        workfile.events.clear
        Timecop.freeze yesterday do
          Events::NoteOnWorkfile.by(user).add(:workspace => workspace, :workfile => workfile, :body => 'note for yesterday')
        end
        Timecop.freeze today do
          Events::NoteOnWorkfile.by(user).add(:workspace => workspace, :workfile => workfile, :body => 'note for today')
        end
        workfile.reload
      end

      it "presents the notes as comments in reverse timestamp order" do
        recent_comments[0][:author].to_hash.should == Presenter.present(user, view)
        recent_comments[0][:body].should == "note for today"
        recent_comments[0][:timestamp].should == today
      end

      it "presents only the last comment" do
        recent_comments.count.should == 1
      end

      it "includes the comment count" do
        hash[:comment_count].should == 2
      end

      context "when there is a comment on a note" do
        let(:comment_timestamp) { today + 2.hours }

        before do
          Timecop.freeze comment_timestamp do
            last_note = workfile.events.last
            FactoryGirl.create :comment, :event => last_note, :body => "comment on yesterday's note", :author => user
          end
        end

        context "when the comment is newer than the notes" do
          it "presents the comment before the notes" do
            recent_comments[0][:author].to_hash.should == Presenter.present(user, view)
            recent_comments[0][:body].should == "comment on yesterday's note"
            recent_comments[0][:timestamp].should == comment_timestamp
          end
        end

        context "when the comment is older than the newest note" do
          let(:comment_timestamp) { today - 2.hours }

          it "presents the comment after the newset note" do
            recent_comments[0][:body].should == "note for today"
          end
        end

        it "includes the comment in the comment count" do
          hash[:comment_count].should == 3
        end
      end
    end

    context "workfile has a draft for that user" do
      it "has_draft value is true" do
        FactoryGirl.create(:workfile_draft, :workfile_id => workfile.id, :owner_id => user.id)
        hash = presenter.to_hash
        hash[:has_draft].should == true
      end
    end

    context "No workfile draft for that user" do
      it "has_draft value is false" do
        hash[:has_draft].should == false
      end
    end

    context ":include_execution_schema is passed as an option" do
      let(:presenter) { WorkfilePresenter.new(workfile, view, :include_execution_schema => true) }

      it "includes the execution_schema" do
        hash[:execution_schema].should == GpdbSchemaPresenter.new(workfile.execution_schema, view).presentation_hash
      end
    end

    it "sanitizes file name" do
      bad_value = 'file_ending_in_invalid_quote"'
      workfile = FactoryGirl.create(:workfile)
      workfile_version = FactoryGirl.create(:workfile_version, :contents => test_file(bad_value), :workfile => workfile)
      json = WorkfilePresenter.new(workfile, view).to_hash

      json[:file_name].should_not include '"'
    end

    context "for activity stream" do
      let(:options) { {:activity_stream => true} }

      it "should not include owner or draft status" do
        hash[:owner].should be_nil
        hash[:has_draft].should be_nil
      end
    end

    describe "when the 'workfile_as_latest_version' option is set" do
      let(:options) { {:workfile_as_latest_version => true} }

      it "calls the presenter for the latest version of the workfile" do
        mock(WorkfilePresenter).present(workfile.latest_workfile_version, anything, {})
        hash
      end

      context "when there is no latest workfile version" do
        before do
          workfile.latest_workfile_version_id = nil
        end

        it "does not try to present the latest workfile version" do
          dont_allow(Presenter).present
          hash
        end
      end
    end
  end

  describe "complete_json?" do
    context "when not including execution schema" do
      it "is not true" do
        presenter.complete_json?.should_not be_true
      end
    end

    context "when including execution schema" do
      let(:options) { {:include_execution_schema => true, :activity_stream => activity_stream} }

      context "when rendering activity stream" do
        let(:activity_stream) { true }
        it "should be false" do
          presenter.should_not be_complete_json
        end
      end

      context "when not rendering for activity stream" do
        let(:activity_stream) { false }
        it "is true" do
          presenter.complete_json?.should be_true
        end
      end
    end
  end
end
