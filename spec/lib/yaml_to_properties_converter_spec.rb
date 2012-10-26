require 'yaml_to_properties_converter'

describe YamlToPropertiesConverter do
  describe '.write_properties' do
    let(:hash) { {
        'namespace' => {'key' => 'value', 'another_key' => 'another_value'},
        'top_level_key' => 'top_level_value'
    }}

    it 'returns a list of properties' do
      YamlToPropertiesConverter.write_properties(hash).should == [
        'namespace.key= value',
        'namespace.another_key= another_value',
        'top_level_key= top_level_value'
      ]
    end
  end

  describe 'convert_yml_to_properties' do
    let(:hash) { Object.new }
    let(:source) { 'spec/lib/fixtures/sample.yml'}
    let(:destination) { 'spec/lib/fixtures/converted.properties'}

    it 'writes to the properties file' do
      YamlToPropertiesConverter.convert_yml_to_properties(source, destination)
      lines = File.read(destination).split("\n")
      lines[0].should == "test1.value1= 10"
      lines[1].should == "test2= 20"
    end

    after do
      File.delete(destination)
    end
  end
end