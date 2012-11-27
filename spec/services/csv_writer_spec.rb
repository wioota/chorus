require 'spec_helper'

describe CsvWriter do
  describe "#to_csv_as_stream" do
    it "returns an enumarable of the csv" do
      columns = ["name", "job", "hobby"]
      rows = [
          ["dr, frank n stein", "physician", "revivalism"],
          ["mickey. mouse", "media mogul", "funny laugh"],
          ["dr n:; gin", "mechanical engineer", "gin"]
      ]

      stream = CsvWriter.to_csv_as_stream(columns, rows)
      stream.next.chomp.should == "name,job,hobby"
      stream.next.chomp.should == '"dr, frank n stein",physician,revivalism'
    end
  end
end