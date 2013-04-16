require 'spec_helper'

describe GnipDataSourceImportsController, :greenplum_integration => true, :type => :controller do
  let(:user) { users(:owner) }
  let(:data_source) { gnip_data_sources(:default) }
  let(:to_table) { "gnip_new_table" }
  let(:workspace) { workspaces(:real) }
  let(:import_params) do
    {
        :gnip_data_source_id => data_source.id,
        :import =>
            {
                :to_table => to_table,
                :new_table => true,
                :workspace_id => workspace.id
            }
    }
  end
  let(:time_string) { '2012-4-23 10:13 -0700' }
  let(:time_thingie) { Time.parse(time_string) }

  before do
    log_in user
    stub(QC.default_queue).enqueue_if_not_queued.with_any_args do |class_and_message, *args|
      className, message = class_and_message.split(".")
      className.constantize.send(message, *args)
    end

    stub(ChorusGnip).from_stream.with_any_args do
      stream = Object.new
      stub(stream).fetch { %w(foo bar) }
      stub(stream).to_result_in_batches(%w(foo)) do
        <<-CSV
hi,hi,hi,#{time_string},hi,hi,hi,#{time_string},hi,4,3,2,1
bye,bye,bye,#{time_string},bye,bye,bye,#{time_string},bye,4,3,2,1
        CSV
      end
      stub(stream).to_result_in_batches(%w(bar)) do
        <<-CSV
yo,yo,yo,#{time_string},yo,yo,yo,#{time_string},yo,4,3,2,1
        CSV
      end
    end
  end

  after do
    workspace.sandbox.connect_as(user).drop_table(to_table)
  end

  it "imports Gnip streams" do
    expect do
      post :create, import_params
      response.should be_success
    end.to change(Dataset, :count).by(1)

    dataset = Dataset.last
    dataset.name.should == to_table
    dataset.schema.should == workspace.sandbox
    dataset.connect_as(user).count_rows(to_table).should == 3
    dataset.connect_as(user).fetch("SELECT * FROM #{dataset.name} ORDER BY id").should == [{:id => "bye", :body => "bye", :link => "bye", :posted_time => time_thingie,
                                                                                :actor_id => "bye", :actor_link => "bye", :actor_display_name => "bye", :actor_posted_time => time_thingie,
                                                                                :actor_summary => "bye", :actor_friends_count => 4, :actor_followers_count => 3, :actor_statuses_count => 2, :retweet_count => 1},
                                                                               {:id => "hi", :body => "hi", :link => "hi", :posted_time => time_thingie,
                                                                                :actor_id => "hi", :actor_link => "hi", :actor_display_name => "hi", :actor_posted_time => time_thingie,
                                                                                :actor_summary => "hi", :actor_friends_count => 4, :actor_followers_count => 3, :actor_statuses_count => 2, :retweet_count => 1},
                                                                               {:id => "yo", :body => "yo", :link => "yo", :posted_time => time_thingie, :actor_id => "yo", :actor_link => "yo",
                                                                                :actor_display_name => "yo", :actor_posted_time => time_thingie, :actor_summary => "yo", :actor_friends_count => 4,
                                                                                :actor_followers_count => 3, :actor_statuses_count => 2, :retweet_count => 1}]
  end
end