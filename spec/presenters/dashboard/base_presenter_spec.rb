require 'spec_helper'

describe Dashboard::BasePresenter, :type => :view do
  before do
    set_current_user(user)
  end

  let(:user) { users(:admin) }
  let(:presenter) { described_class.new(model, view) }
  let(:hash) { presenter.to_hash }

  context 'for SiteSnapshot' do
    let(:model) { Dashboard::SiteSnapshot.new({}).fetch! }

    it 'hash should have attributes' do
      hash[:data].should == model.result
    end
  end
end
