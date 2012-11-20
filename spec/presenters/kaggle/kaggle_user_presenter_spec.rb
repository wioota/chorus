require 'spec_helper'

describe KaggleUserPresenter, :type => :view do
  let(:kaggle_user) { KaggleApi.users.first }
  let(:presenter) { KaggleUserPresenter.new(kaggle_user, view) }

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    it "should include the correct keys" do
      hash.should have_key('id')
      hash.should have_key('username')
      hash.should have_key('location')
      hash.should have_key('rank')
      hash.should have_key('points')
      hash.should have_key('number_of_entered_competitions')
      hash.should have_key('gravatar_url')
      hash.should have_key('full_name')
      hash.should have_key('favorite_technique')
      hash.should have_key('favorite_software')
    end
  end
end