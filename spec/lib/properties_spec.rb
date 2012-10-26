require 'properties'
require 'spec/support/rr'

describe '.load_file' do
  let(:translation_string) { <<-EOF
    quux=Non-nested
    test.foo=Bar
    test.bar.baz=Stuff
    types.number=42
    types.negative=-7
    types.decimal=-7.5
    types.true=true
    types.false=false

    #I am a comment
    #comment= comment_value
    multiline=\\
        line2\\
        line3
    value_with_equal_sign=1+1=2
    whitespace = a_value
  EOF
  }

  let(:hash) {
    stub(File).read('some_file_name') { translation_string }
    Properties.load_file('some_file_name')
  }

  it 'returns non-nested string' do
    hash["quux"].should == "Non-nested"
  end

  it "handles nested keys" do
    hash["test"]["foo"].should == 'Bar'
    hash["test"]["bar"]["baz"].should == 'Stuff'
  end

  it "strips whitespace" do
    hash["whitespace"].should == "a_value"
  end

  it "handles comments, and blank lines" do
    topLevelKeys = ['quux', 'test', 'multiline', 'value_with_equal_sign', 'whitespace', 'types']

    hash.keys.should =~ topLevelKeys
  end

  it "handles equal signs in the value" do
    hash["value_with_equal_sign"].should == '1+1=2'
  end

  it "handles multi line translations" do
    hash["multiline"].should include('line2')
    hash["multiline"].should include('line3')
    hash["multiline"].should_not include('\\')
  end

  describe "type casting" do
    it "handles numbers" do
      hash["types"]["number"].should == 42
      hash["types"]["number"].to_s.should == "42"
      hash["types"]["negative"].should == -7
      hash["types"]["decimal"].should == -7.5
    end

    it "handles booleans" do
      hash["types"]["true"].should == true
      hash["types"]["false"].should == false
    end
  end

end