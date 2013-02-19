require 'spec_helper'

resource 'Tags' do
  let(:owner) { users(:owner) }
  let(:workfile) { workfiles("sql.sql") }

  before do
    log_in owner
  end

  post '/taggings' do
    parameter :entity_id, 'Id of the associated object'
    parameter :entity_type, 'Type of the associated object, e.g. Workfile or Dataset'
    parameter :'tag_names[]', 'Tag names (100 characters or less)'

    required_parameters :entity_id, :entity_type, :'tag_names[]'

    let(:entity_id) { workfile.to_param }
    let(:entity_type) { 'Workfile' }
    let(:'tag_names[]') { ['alpha', 'omega'] }

    example_request 'Set tags for a workfile or dataset' do
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
    parameter :id, 'Id of the tag to delete'

    let(:id) { Tag.first.id }

    example_request 'Delete a tag' do
      status.should == 200
    end
  end
end
