require 'spec_helper'

describe WorkspaceImport do
  let(:import) { imports(:one) }

  describe 'associations' do
    it { should belong_to :workspace }
    it { should belong_to :import_schedule }
  end

  describe '#schema' do
    it 'is the sandbox of the workspace' do
      import.schema.should == import.workspace.sandbox
    end
  end
end