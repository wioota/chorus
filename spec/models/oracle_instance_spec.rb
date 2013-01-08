require 'spec_helper'

describe OracleInstance do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:host) }
    it { should validate_presence_of(:port) }
    it { should validate_presence_of(:db_name) }
  end
end