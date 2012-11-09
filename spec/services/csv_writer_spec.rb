require 'spec_helper'

describe CsvWriter do
  describe "#to_csv" do
    it "returns CSV" do
      columns = ["name", "job", "hobby"]
      rows = [
          ["dr, frank n stein", "physician", "revivalism"],
          ["mickey. mouse", "media mogul", "funny laugh"],
          ["dr n:; gin", "mechanical engineer", "gin"]
      ]
      CsvWriter.to_csv(columns, rows).should == <<CSV
name,job,hobby
"dr, frank n stein",physician,revivalism
mickey. mouse,media mogul,funny laugh
dr n:; gin,mechanical engineer,gin
CSV
    end
  end
end