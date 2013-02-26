require 'spec_helper'

describe DataSource do
  describe 'creating a DataSource' do
    it 'enqueues a refresh job' do
      mock(QC.default_queue).enqueue_if_not_queued('DataSource.refresh', anything, hash_including('new' => true))
      FactoryGirl.create(:data_source)
    end
  end

  describe 'automatic reindexing' do
    let(:data_source) { data_sources(:oracle) }

    before do
      stub(Sunspot).index.with_any_args
    end

    context 'making the data source shared' do
      it 'enqueues a reindex job' do
        mock(data_source).solr_reindex_later
        data_source.shared = true
        data_source.save
      end
    end

    context 'making the data source un-shared' do
      let(:data_source) { data_sources(:shared) }
      
      it 'enqueues a reindex job' do
        mock(data_source).solr_reindex_later
        data_source.shared = false
        data_source.save
      end
    end

    context 'not changing the shared state' do
      it 'doesnt reindex' do
        dont_allow(data_source).solr_reindex_later
        data_source.update_attributes(:name => 'foo')
      end
    end
  end

  describe '#solr_reindex_later' do
    let(:data_source) { data_sources(:owners) }

    it 'enqueues a job' do
      mock(QC.default_queue).enqueue_if_not_queued('DataSource.reindex_data_source', data_source.id)
      data_source.solr_reindex_later
    end
  end

  describe '#reindex_data_source' do
    let(:data_source) { data_sources(:owners) }

    before do
      stub(Sunspot).index.with_any_args
    end

    it 'reindexes itself' do
      mock(Sunspot).index(data_source)
      DataSource.reindex_data_source(data_source.id)
    end

    it 'should reindex all of its datasets' do
      mock(Sunspot).index(is_a(Dataset)).times(data_source.datasets.count)
      DataSource.reindex_data_source(data_source.id)
    end
  end

  describe '.refresh' do
    let(:data_source) { data_sources(:owners) }

    before do
      any_instance_of(DataSource) do |data_source|
        stub(data_source).refresh { @refreshed_data_source = true }
      end
    end

    it 'calls refresh on the instance' do
      DataSource.refresh(data_source.id)
      @refreshed_data_source.should be_true
    end
  end

  describe '#refresh' do
    let(:data_source) { data_sources(:owners) }

    it 'refreshes databases for the data source' do
      mock(data_source).refresh_databases({})
      stub(data_source).refresh_all
      data_source.refresh
    end

    it 'calls refresh all' do
      stub(data_source).refresh_databases
      mock(data_source).refresh_schemas({})
      data_source.refresh
    end

    context 'when new is set' do
      it 'calls refresh all twice, the first time skipping the dataset solr indexing, the second time forcing it' do
        stub(data_source).refresh_databases
        mock(data_source).refresh_schemas(hash_including(:skip_dataset_solr_index => true))
        mock(data_source).refresh_schemas(hash_including(:force_index => true))
        data_source.refresh(:new => true)
      end
    end
  end

  describe '#refresh_databases_later' do
    let(:data_source) { data_sources(:owners) }

    it 'should enqueue a job' do
      mock(QC.default_queue).enqueue_if_not_queued('DataSource.refresh_databases', data_source.id)
      data_source.refresh_databases_later
    end
  end
end