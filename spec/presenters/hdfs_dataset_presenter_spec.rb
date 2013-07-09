require 'spec_helper'

describe HdfsDatasetPresenter, :type => :view do
  let(:dataset) { datasets(:hadoop) }
  let(:presenter) { HdfsDatasetPresenter.new(dataset, view) }
  let(:hash) { presenter.to_hash }

  it "includes appropriate fields and associates" do
    hash.should_not be_empty
    hash[:id].should == dataset.id
    hash[:file_mask].should == dataset.file_mask
    hash[:object_name].should == dataset.name
    hash[:hdfs_data_source][:id].should == dataset.hdfs_data_source.id
    hash[:hdfs_data_source][:name].should == dataset.hdfs_data_source.name
  end
end