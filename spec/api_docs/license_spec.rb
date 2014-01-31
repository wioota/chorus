require 'spec_helper'

resource 'License' do
  let(:user) { users(:admin) }

  get '/license' do
    before do
      log_in user
    end

    example_request 'Get license info' do
      status.should == 200
    end
  end
end
