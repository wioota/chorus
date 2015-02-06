require 'spec_helper'

describe GpdbTableAccess do
  let(:context) { Object.new }
  let(:access) { GpdbTableAccess.new(context)}
  let(:dataset) { datasets(:default_table) }

  it_behaves_like 'dataset access control'
end
