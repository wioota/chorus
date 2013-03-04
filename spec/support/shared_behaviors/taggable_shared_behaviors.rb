shared_examples "taggable models" do |fixture_data|

  let(:model) { send(*fixture_data) }

  it "creates tags for a string array" do
    model.tags.should be_blank
    model.tag_list = %w{foo bar baz}
    model.tags.map(&:name).should =~ ["foo", "bar", "baz"]
  end

  it "removes tags not included in the list" do
    model.tag_list = ["foo", "bar"]
    model.save!

    model.tag_list = ["foo", "baz"]
    model.save!
    model.tags.map(&:name).should =~ ["foo", "baz"]
  end

  it "is taggable" do
    model.class.should be_taggable
  end
end