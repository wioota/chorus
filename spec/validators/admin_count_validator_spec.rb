require 'spec_helper'

class AdminValidatable
  include ActiveModel::Validations
  validates_with AdminCountValidator
  attr_accessor :admin
end

describe AdminCountValidator do

  let(:user) { AdminValidatable.new }

  before do
    stub(License.instance).[](:admins) { 10 }
    stub(user).admin_changed? { true }
  end

  context 'with the open chorus license' do
    before do
      stub(License.instance).[](:vendor) { License::OPEN_CHORUS }
      mock(user).admin?.never
      mock(User).admin_count.never
    end

    it 'validates without checking User#admin? or User.admin_count' do
      user.should be_valid
    end
  end

  context 'with a vendored license' do
    before do
      stub(License.instance).[](:vendor) { 'my_vendor' }
    end

    context 'user is designated as a admin' do
      before do
        mock(user).admin? { true }
      end

      it 'validates if the number of existing admins is less than the limit' do
        stub(User).admin_count { 9 }
        user.should be_valid
      end

      context 'admin was changed to true' do
        before do
          stub(user).admin_changed? { true }
        end

        it 'does not validate if the number of existing admins is greater than or equal to the limit' do
          stub(User).admin_count { 10 }
          user.should_not be_valid
        end
      end

      context 'an existing admin' do
        before do
          stub(user).admin_changed? { false }
        end

        it 'validates if the number of existing admins is equal to the limit' do
          stub(User).admin_count { 10 }
          user.should be_valid
        end

        it 'does not validate if the number of existing admins is greater than the limit' do
          stub(User).admin_count { 11 }
          user.should_not be_valid
        end
      end

    end

    context 'user is not designated as a admin' do
      before do
        mock(user).admin? { false }
      end

      [9,10,11].each do |count|
        context "when current admin count is #{count}" do
          before { stub(User).admin_count { count } }
          it('validates') { user.should be_valid }
        end
      end
    end
  end
end
