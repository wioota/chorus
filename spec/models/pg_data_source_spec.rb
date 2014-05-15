require 'spec_helper'

describe PgDataSource do

  it { should have_many :databases }

  describe '#destroy' do
    let(:data_source) { data_sources(:postgres) }

    before do
      any_instance_of(PostgresConnection) { |connection| stub(connection).running? }
    end

    it 'enqueues a destroy_databases job' do
      mock(QC.default_queue).enqueue_if_not_queued('Database.destroy_databases', data_source.id)
      data_source.destroy
    end
  end

  it_should_behave_like :data_source_with_access_control
  it_should_behave_like :data_source_with_db_name_port_validations

  it_behaves_like(:data_source_with_update) do
    let(:data_source) { data_sources(:postgres) }
  end

end
