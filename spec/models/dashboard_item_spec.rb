require 'spec_helper'

describe DashboardItem do
  describe 'validations' do
    it { should ensure_inclusion_of(:name).in_array(%w(Module1 Module2 Module3)) }
  end
end
