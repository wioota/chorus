require "spec_helper"

describe Mailer do
  describe '#notify' do
    let(:event) { Events::JobSucceeded.last }
    let(:user) { users(:the_collaborator) }
    let(:sent_mail) { Mailer.notify(user, event) }

    it 'renders the notification header as the subject line' do
      sent_mail.subject.should == event.header
    end

    it 'renders the receiver email' do
      sent_mail.to.should == [user.email]
    end

    it "adds to the Deliveries list" do
      expect do
        sent_mail
      end.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    context "the event is a JobSucceeded/JobFailed" do
      it "has a body with the job name and workspace name" do
        encoded_body = sent_mail.body.encoded
        encoded_body.should include event.job.name
        encoded_body.should include event.workspace.name
      end

      it "includes all of the job task results" do
        encoded_body = sent_mail.body.encoded
        results = event.job_result.job_task_results
        results.length.should be > 0
        results.each do |result|
          encoded_body.should include result.name
        end
      end

      describe 'successful jobs' do
        it "says the job succeeded" do
          sent_mail.body.encoded.should include 'succeeded'
        end
      end

      describe 'failing jobs' do
        let(:event) { Events::JobFailed.last }

        it "says the job failed" do
          sent_mail.body.encoded.should include 'failed'
        end
      end
    end
  end
end
