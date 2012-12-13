ENV["RAILS_ENV"] ||= 'test'

RSpec.configure do |config|
  config.mock_with :rr
  config.treat_symbols_as_metadata_keys_with_true_values = true
end
