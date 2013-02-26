require "spec_helper"

describe DataSource do
  describe ".refresh" do
    let(:data_source) { data_sources(:owners) }

    before do
      any_instance_of(DataSource) do |data_source|
        stub(data_source).refresh { @refreshed_data_source = true }
      end
    end

    it "calls refresh on the instance" do
      DataSource.refresh(data_source.id)
      @refreshed_data_source.should be_true
    end
  end

  describe "#refresh" do
    let(:data_source) { data_sources(:owners) }

    it "refreshes databases for the data source" do
      mock(data_source).refresh_databases({})
      stub(data_source).refresh_all
      data_source.refresh
    end

    it "calls refresh all" do
      stub(data_source).refresh_databases
      mock(data_source).refresh_schemas({})
      data_source.refresh
    end

    context "when new is set" do
      it "calls refresh all twice, the first time skipping the dataset solr indexing, the second time forcing it" do
        stub(data_source).refresh_databases
        mock(data_source).refresh_schemas(hash_including(:skip_dataset_solr_index => true))
        mock(data_source).refresh_schemas(hash_including(:force_index => true))
        data_source.refresh(:new => true)
      end
    end
  end

  describe "#refresh_databases_later" do
    let(:data_source) { data_sources(:owners) }

    it "should enqueue a job" do
      mock(QC.default_queue).enqueue_if_not_queued("DataSource.refresh_databases", data_source.id)
      data_source.refresh_databases_later
    end
  end
end