require 'spec_helper'

describe OracleInstance do
  it { should validate_presence_of(:host) }
  it { should validate_presence_of(:port) }
end