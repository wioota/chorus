require 'spec_helper'

resource "Greenplum DB: data sources" do
  let(:owner) { owned_instance.owner }
  let(:owned_instance) { data_sources(:shared)}
  let(:new_owner) { users(:no_collaborators) }

  before do
    log_in owner
    any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? {true} }
  end

  put "/data_sources/:data_source_id/owner" do
    parameter :data_source_id, "Greenplum data source id"
    parameter :id, "The new owner's user id"

    required_parameters :data_source_id, :id

    let(:data_source_id) { owned_instance.to_param }
    let(:id) { new_owner.to_param }

    example_request "Change the owner of an data source" do
      status.should == 200
    end
  end
end
