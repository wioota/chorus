require 'spec_helper'

resource 'Tags' do
  let(:user) { users(:owner) }
  let(:workfile) { workfiles("sql.sql") }

  before do
    log_in user
  end

  post '/taggings' do
    parameter :taggables, 'An array of objects to be tagged, each with form {entity_id: <num>, entity_type: <type>}'
    parameter :add, 'Tag name (100 characters or less)'
    required_parameters :taggables

    let(:taggables) { { "0" => {entity_id: workfile.to_param, entity_type: Workfile} } }
    let(:add) { 'alpha' }

    example_request 'Adding a tag to multiple entities' do
      status.should == 201
    end
  end

  post '/taggings' do
    parameter :taggables, 'An array of objects to be tagged, each with form {entity_id: <num>, entity_type: <type>}'
    parameter :remove, 'Tag name'
    required_parameters :taggables

    before do
      workfile.tag_list = ['alpha']
    end

    let(:taggables) { { "0" => {entity_id: workfile.to_param, entity_type: Workfile} } }
    let(:remove) { 'alpha' }

    example_request 'Removing a tag from multiple entities' do
      status.should == 201
    end
  end

  get '/tags' do
    parameter :query, 'String to search tags for'

    let(:query) { "something" }

    example_request 'Search tags' do
      status.should == 200
    end
  end

  put '/tags/:id' do
    parameter :id, 'Id of the tag to rename'
    parameter :name, 'Tag name (100 characters or less)'

    let(:id) { Tag.first.id }
    let(:name) { "myTag" }

    example_request 'Rename a tag' do
      status.should == 200
    end
  end

  delete '/tags/:id' do
    let(:user) { users(:admin) }
    let(:id) { Tag.first.id }

    parameter :id, 'Id of the tag to delete'


    example_request 'Delete a tag' do
      status.should == 200
    end
  end
end
