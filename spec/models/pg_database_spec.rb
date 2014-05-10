require 'spec_helper'

describe PgDatabase do
  context 'associations' do
    it { should have_many(:schemas).class_name('PgSchema') }
  end
end
