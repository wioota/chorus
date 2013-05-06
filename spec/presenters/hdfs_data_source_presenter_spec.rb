require 'spec_helper'

describe HdfsDataSourcePresenter, :type => :view do
  let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
  let(:user) { hdfs_data_source.owner }
  let(:presenter) { HdfsDataSourcePresenter.new(hdfs_data_source, view, options) }
  let(:options) { {} }

  before do
    set_current_user(user)
  end

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    it "should have the correct keys" do
      hash.should have_key(:name)
      hash.should have_key(:host)
      hash.should have_key(:port)
      hash.should have_key(:id)
      hash.should have_key(:is_deleted)
      hash.should have_key(:owner)
      hash.should have_key(:description)
      hash.should have_key(:version)
      hash.should have_key(:username)
      hash.should have_key(:group_list)
      hash.should have_key(:online)
      hash.should have_key(:tags)
      hash[:entity_type].should == 'hdfs_data_source'
    end

    it "should use ownerPresenter Hash method for owner" do
      owner = hash[:owner]
      owner.to_hash.should == (UserPresenter.new(user, view).presentation_hash)
    end

    it_behaves_like "activity stream data source presenter"
    it_behaves_like :succinct_data_source_presenter
  end
end