require 'spec_helper'

resource 'Dashboard' do
  let(:user) { users(:admin) }

  before do
    log_in user
  end

  post '/dashboards/recent_workspaces' do

    parameter :action, 'The action you want to take for Recent Workspaces<br><br>
                          - "updateOption": Updates the number of recent workspaces to display (requires "option_value" parameter)
                          - "clearList": Clears list of recent workspaces'
    parameter :option_value, 'For "updateOption", the number of recent workspaces to display in the module'
    required_parameters :action

    let(:action) { 'updateOption' }
    let(:option_value) { '5' }

    example_request 'Update the state of Recent Workspaces module' do
      status.should == 200
    end
  end
end
