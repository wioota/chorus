require 'spec_helper'

describe LicensePresenter, :type => :view do
  let(:license) { License.instance }
  before do
    stub.proxy(license).[](anything)
  end

  let(:presenter) { LicensePresenter.new(license, view, {}) }
  let(:hash) { presenter.to_hash }

  let(:sample) do
    {
      :admins => 5,
      :developers => 10,
      :collaborators => 100,
      :level => 'triple-platinum',
      :vendor => 'chorus',
      :organization_uuid => 'o-r-g',
      :expires => Date.parse('2014-07-31')
    }
  end

  describe 'to_hash' do
    it 'includes the license key/value pairs' do
      sample.each do |key, value|
        stub(license).[](key) { value }
      end

      sample.each do |key, value|
        hash[key].should == value
      end
    end
  end
end
