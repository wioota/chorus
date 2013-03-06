shared_examples_for 'a subclass of schema' do
  context ".refresh" do
    let(:schema_parent) do
      stub(schema.parent).connect_with(account) { connection }
      schema.parent
    end
    let(:account) { Object.new }
    let(:connection) { Object.new }
    let(:dropped_schema) { schema_parent.schemas.where("id <> #{schema.id} AND name <> 'new_schema'").first! }

    before(:each) do
      stub(Dataset).refresh
      stub(connection).schemas { ["new_schema", schema.name] }
    end

    it "creates new copies of the schemas in our db" do
      Schema.refresh(account, schema_parent)
      schema_parent.schemas.where(:name => "new_schema").should exist
    end

    it "refreshes all Datasets when :refresh_all is true, passing the options to schema refresh_datasets" do
      options = {:dostuff => true, :refresh_all => true}
      mock(Dataset).refresh(account, anything, options).times(2)
      Schema.refresh(account, schema_parent, options)
    end

    it "does not re-create schemas that already exist in our schema_parent" do
      Schema.refresh(account, schema_parent)
      expect {
        Schema.refresh(account, schema_parent)
      }.not_to change(Schema, :count)
    end

    it "marks schema as stale if it does not exist" do
      Schema.refresh(account, schema_parent, :mark_stale => true)
      dropped_schema.should be_stale
      dropped_schema.stale_at.should be_within(5.seconds).of(Time.current)
    end

    it "does not mark schema as stale if flag is not set" do
      Schema.refresh(account, schema_parent)
      dropped_schema.should_not be_stale
    end

    it "does not update the stale_at time" do
      Timecop.freeze(1.year.ago) do
        dropped_schema.mark_stale!
      end
      Schema.refresh(account, schema_parent, :mark_stale => true)
      dropped_schema.reload.stale_at.should be_within(5.seconds).of(1.year.ago)
    end

    it "clears stale flag on schema if it is found again" do
      schema.mark_stale!
      Schema.refresh(account, schema_parent)
      schema.reload.should_not be_stale
    end

    context "when the schema_parent is not available" do
      before do
        stub(connection).schemas { raise DataSourceConnection::Error.new }
      end

      it "marks all the associated schemas as stale if mark_stale is set" do
        Schema.refresh(account, schema_parent, :mark_stale => true)
        schema.reload.should be_stale
      end

      it "does not mark the associated schemas as stale if mark_stale is not set" do
        Schema.refresh(account, schema_parent)
        schema.reload.should_not be_stale
      end

      it "should return an empty array" do
        Schema.refresh(account, schema_parent).should == []
      end
    end
  end

  it_should_behave_like 'something that can go stale' do
    let(:model) { schema }
  end
end