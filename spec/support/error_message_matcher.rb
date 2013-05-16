RSpec::Matchers.define :have_error_on do |attribute|
  chain :with_message do |message_key|
    @message_key = message_key
  end

  chain :with_options do |options|
    @options = options
  end

  match do |model|
    @errors_on_attribute = model.errors[attribute]
    @errors_on_attribute.should_not be_nil

    if @message_key
      @errors_on_attribute_with_key = @errors_on_attribute.select { |error| error[0] == @message_key }
      @errors_on_attribute_with_key.should_not be_empty

      if @options
        @errors_on_attribute_with_key_and_options = @errors_on_attribute_with_key.select { |error| error[1] == @options }
        @errors_on_attribute_with_key_and_options.should_not be_empty
      end
    end

    true
  end

  failure_message_for_should do |model|
    if @errors_on_attribute.nil?
      "model had no errors on #{attribute}, actual errors were #{model.errors.inspect}"
    elsif @errors_on_attribute_with_key.empty?
      "model had no errors on #{attribute} with #{@message_key.inspect}, actual errors on #{attribute} were #{@errors_on_attribute.inspect}"
    elsif @errors_on_attribute_with_key_and_options.empty?
      "model had no errors on #{attribute} with #{@message_key.inspect} and #{@options.inspect}, actual errors on #{attribute} were #{@errors_on_attribute_with_key.inspect}"
    end
  end

  failure_message_for_should_not do |model|
    "model should not have error #{@message_key.inspect} on attribute #{attribute}, with options #{@options.inspect}, but did"
  end
end