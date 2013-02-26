shared_examples "taggable models" do |fixture_data|

  let(:model) { send(*fixture_data) }

  it "creates tags from a comma separated list" do
    model.tags.should be_blank
    model.tag_list = "foo,bar,baz"
    model.tags.map(&:name).should =~ ["foo", "bar", "baz"]
  end

  it "does not allow duplicates" do
    model.tag_list = "foo,bar"
    model.tag_list = "foo,baz"
    model.tag_list = "FoO"
    model.tags.map(&:name).should =~ ["foo", "bar", "baz"]
  end

  it "is taggable" do
    model.class.should be_taggable
  end

end