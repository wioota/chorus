require 'spec_helper'
require 'validator'

describe 'Validator' do
  describe '.valid?' do
    it "returns true if the data sources are all valid" do
      Validator.valid?.should be_true
    end

    context "when there are invalid data sources" do
      let(:duplicate_name) { HadoopInstance.first.name }

      before do
        bad_instance = GpdbInstance.first
        bad_instance.name = duplicate_name
        bad_instance.save! :validate => false
      end
      it "returns false" do
        Validator.valid?.should be_false
      end

      it "logs a message with the duplicate names" do
        mock(Validator).log("Duplicate data source names found: #{duplicate_name}")
        Validator.valid?
      end
    end
  end
end
