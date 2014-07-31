require 'spec_helper'

describe DashboardConfig do
  let(:user) { FactoryGirl.create(:user) }
  let(:subject) { described_class.new(user) }

  describe '#dashboard_items' do

    context 'when the user has dashboard items' do
      before do
        DashboardItem::ALLOWED_MODULES.reverse.each_with_index do |name, i|
          user.dashboard_items.create!(:name => name, :location => i)
        end
      end

      it 'returns the dashboard item names' do
        subject.dashboard_items.should == DashboardItem::ALLOWED_MODULES.reverse
      end
    end

    context 'when the user has no dashboard items' do
      it 'returns the default list' do
        subject.dashboard_items.should == DashboardItem::DEFAULT_MODULES
      end
    end
  end
end
