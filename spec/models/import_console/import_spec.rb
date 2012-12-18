require 'spec_helper'

describe ImportConsole::Import do
  let!(:pending_import) {
    import = imports :one
    import.update_attribute :finished_at, nil
    ImportConsole::Import.new(import)
  }

  describe ".started?" do
    #enqueued? = QC.default_queue.job_count()
    before do
      QC.delete_all
      QC.enqueue("ImportExecutor.run", pending_import.id)
    end

    context "when the import is in the worker queue" do
      it "should not mark the import as started" do
        pending_import.should_not be_started
      end
    end

    context "when worker has starting processing the import from the queue" do
      let(:chorus_worker) { ChorusWorker.new :fork_worker => false }

      xit "should report started" do
        catch :running! do
          stub(ImportExecutor).run { throw :running! }
          chorus_worker.start
        end
        pending_import.reload.should be_started
      end
    end
  end
end