require 'rubygems'
require 'rspec/core/formatters/progress_formatter'

class WrappingProgressFormatter < RSpec::Core::Formatters::ProgressFormatter
  def example_passed(example)
    super(example)
    wrap
  end

  def example_pending(example)
    super(example)
    wrap
  end

  def example_failed(example)
    super(example)
    wrap
  end

  def wrap
    increment_wrap_counter
    if wrap_counter % 80 == 0
      output.puts
    end
  end

  def wrap_counter
    @wrap_counter || 0
  end

  def increment_wrap_counter
    @wrap_counter = wrap_counter + 1
  end
end