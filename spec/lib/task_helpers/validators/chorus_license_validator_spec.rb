require 'spec_helper'
describe ChorusLicenseValidator do

  before :each do
    stub(ChorusLicenseValidator).log
  end

  describe '.run' do

    let (:license) { License.new }

    it "warns the user if the license is expired" do
      stub(license).expired? { true }

      ChorusLicenseValidator.run(license)
      ChorusLicenseValidator.should have_received.log("  Warning: the Chorus licence is expired, using default 'openchorus' license")
    end

    it "warns the user if the license does not exist" do
      stub(license).exists? { false }

      ChorusLicenseValidator.run(license)
      ChorusLicenseValidator.should have_received.log("  Warning: could not find Chorus license, using default 'openchorus' license")
    end
  end
end