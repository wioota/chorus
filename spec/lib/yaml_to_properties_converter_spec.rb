require 'yaml_to_properties_converter'

describe YamlToPropertiesConverter do
  describe 'convert_yml_to_properties' do
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