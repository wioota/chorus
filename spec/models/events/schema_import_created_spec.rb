require 'spec_helper'
require_relative 'helpers'

describe Events::SchemaImportCreated do
  extend EventHelpers
  let(:actor) { users(:owner) }
  let(:destination_dataset) { datasets(:table) }
  let(:source_dataset) { datasets(:oracle_table) }
  let(:schema) { schemas(:oracle) }

  subject do
    Events::SchemaImportCreated.add(
      :actor => actor,
      :dataset => destination_dataset,
      :source_dataset => source_dataset,
      :schema_id => schema.id,
      :destination_table => 'non_existent_table'
    )
  end

  its(:dataset) { should == destination_dataset }
  its(:source_dataset) { should == source_dataset }
  its(:additional_data) { should == {'schema_id' => schema.id,
                                     'destination_table' => 'non_existent_table'}
  }

  its(:schema) { should == schema }

  it_creates_activities_for { [actor, destination_dataset, source_dataset] }
  it_does_not_create_a_global_activity
end
