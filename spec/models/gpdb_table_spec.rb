require 'spec_helper'

describe GpdbTable do
  it_behaves_like 'a dataset table' do
    let(:table) { datasets(:default_table) }
  end
end
