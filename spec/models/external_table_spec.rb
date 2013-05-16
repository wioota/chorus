require 'spec_helper'

describe ExternalTable do
  let(:database) { Object.new }
  let(:params) do
    {
        :database => database,
        :schema_name => 'public',
        :column_names => ['field1', 'field2'],
        :column_types => ['text', 'text'],
        :name => 'foo',
        :location_url => 'gphdfs://foo',
        :delimiter => ','
    }
  end

  it "should validate the presence of attributes" do
    [:column_names, :column_types, :name, :location_url].each do |a|
      e = ExternalTable.new(params.merge(a => nil))
      e.should_not be_valid
      e.should have_error_on(a)
    end
  end

  it "should be valid for any delimiters including the space character" do
    [',', ' ', "\t"].each do |d|
      e = ExternalTable.new(params.merge(:delimiter => d))
      e.should be_valid
    end
  end

  it "should be invalid for no delimiter" do
    ['', 'ABCD'].each do |d|
      e = ExternalTable.new(params.merge(:delimiter => d))
      e.should_not be_valid
      e.errors.first.should == [:delimiter, [:EMPTY, {}]]
    end
  end

  it "should save successfully" do
    e = ExternalTable.new(params)
    mock(database).create_external_table(
        {
            :table_name => "foo",
            :columns => "field1 text, field2 text",
            :location_url => "gphdfs://foo",
            :delimiter => ","
        })
    e.save
  end

  it "should not save if invalid" do
    e = ExternalTable.new(params.merge(:name => nil))
    dont_allow(database).create_external_table
    e.save.should be_false
    e.should have_error_on(:name).with_message(:blank)
  end

  context "when saving fails" do
    it "adds table already exists error when the table already exists" do
      e = ExternalTable.new(params)
      stub(database).create_external_table.with_any_args do
        raise GreenplumConnection::DatabaseError.new(StandardError.new())
      end

      e.save.should be_false
      e.should have_error_on(:name).with_message(:TAKEN)
    end
  end

  context "creating an external table from a directory" do
    it "create the table" do
      e = ExternalTable.new(params.merge(:file_pattern => "*.csv", :location_url => 'gphdfs://foo'))
      mock(database).create_external_table(
          {
              :table_name => "foo",
              :columns => "field1 text, field2 text",
              :location_url => "gphdfs://foo/*.csv",
              :delimiter => ","
          })
      e.save
    end
  end
end