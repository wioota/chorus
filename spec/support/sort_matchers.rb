RSpec::Matchers.define :be_sorted_by do |attribute|
  match do |list|
    attributes = list.map(&attribute)
    attributes.should == attributes.sort
  end

  description do |list|
    "#{list.inspect} to be sorted by '#{attribute.to_s}'"
  end
end