require 'spec_helper'

describe ImportManager do
  let!(:pending_import) {
    import = imports :one
    import.update_attribute :finished_at, nil
    ImportManager.new(import)
  }

  describe "#started?" do
    #enqueued? = QC.default_queue.job_count()
    before do
      QC.delete_all
      QC.enqueue("ImportExecutor.run", pending_import.id)
    end

    context "when the import is in the worker queue" do
      it "should not mark the import as started" do
        expect(pending_import).not_to be_started
      end
    end

    context "when worker has started processing the import from the queue" do
      let(:chorus_worker) { ChorusWorker.new :fork_worker => false }

      xit "should report started" do
        catch :running! do
          stub(ImportExecutor).run { throw :running! }
          chorus_worker.start
        end
        expect(pending_import).to be_started
      end
    end
  end
end