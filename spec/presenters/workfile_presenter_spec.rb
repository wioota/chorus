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
      hash.should have_key(:is_deleted)
      hash.should have_key(:recent_comments)
      hash.should have_key(:comment_count)
      hash.should have_key(:tags)
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

    it "uses the entity_type for type" do
      stub(workfile).entity_type { 'something' }
      hash[:type].should == 'something'
    end

    context "when the workfile has tags" do
      let(:workfile) { workfiles(:tagged) }

      it 'includes the tags' do
        hash[:tags].count.should be > 0
        hash[:tags].should == Presenter.present(workfile.tags, @view)
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

    context "for activity stream" do
      let(:options) { {:activity_stream => true} }

      it "should not include owner or draft status" do
        hash[:owner].should be_nil
        hash[:has_draft].should be_nil
      end
    end

    describe "complete_json?" do
      context "when rendering activity stream" do
        let(:options) { {:activity_stream => true} }
        it "should be false" do
          presenter.should_not be_complete_json
        end
      end

      context "when not rendering for activity stream" do
        let(:options) { {:activity_stream => false} }
        it "is true" do
          presenter.complete_json?.should be_true
        end
      end
    end

    context "for a model with additional_data" do
      class WorkfileWithAdditionalData < Workfile
        has_additional_data :test
      end

      let(:workfile) { WorkfileWithAdditionalData.new(:file_name => 'fn', :test => 'test_value') }

      it "includes the additional_data values" do
        hash['test'].should == 'test_value'
      end
    end
  end
end
