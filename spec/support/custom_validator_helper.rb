module CustomValidators
  def check_validates_with(validator)
    any_instance_of(validator) do |instance|
      mock(instance).validate(subject).any_number_of_times { true }
    end

    subject.valid?
  end

  shared_examples "it validates with DataSourceNameValidator" do
    it "validates with DataSourceNameValidator" do
      check_validates_with(DataSourceNameValidator)
    end
  end
end