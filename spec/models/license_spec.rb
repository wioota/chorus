require 'spec_helper'
require 'fakefs/spec_helpers'

describe License do
  include FakeFS::SpecHelpers
  let(:config_dir) { Rails.root.join('config') }

  before do
    FileUtils.mkdir_p(config_dir.to_s)
    File.open(config_dir.join('chorus.license.default').to_s, 'w') do |file|
      file << <<-LIC
LS0tCjpsaWNlbnNlOgogIG9yZ2FuaXphdGlvbl91dWlkOgogIGFkbWluczog
LTEKICBkZXZlbG9wZXJzOiAtMQogIGNvbGxhYm9yYXRvcnM6IC0xCiAgbGV2
ZWw6IG9wZW5jaG9ydXMKICB2ZW5kb3I6IG9wZW5jaG9ydXMKICBleHBpcmVz
OiAyMDUwLTAxLTAxCg==
      LIC
    end
  end

  let(:license) { License.new }

  context 'when there is no chorus.license' do
    it 'reads from chorus.license.default' do
      File.exists?(config_dir.join 'chorus.license').should be_false
      license[:organization_uuid].should be_nil
      license[:admins].should == -1
      license[:developers].should == -1
      license[:collaborators].should == -1
      license[:level].should == 'openchorus'
      license[:vendor].should == 'openchorus'
      license[:expires].should == Date.parse('2050-01-01')
    end
  end

  context 'when there is a chorus.license' do
    before do
      File.open(config_dir.join('chorus.license').to_s, 'w') do |file|
        file << <<-LIC
LS0tCjpsaWNlbnNlOgogIG9yZ2FuaXphdGlvbl91dWlkOgogIGFkbWluczog
LTEKICBkZXZlbG9wZXJzOiAtMQogIGNvbGxhYm9yYXRvcnM6IC0xCiAgbGV2
ZWw6IG9wZW5jaG9ydXMKICB2ZW5kb3I6IGN1c3RvbQogIGV4cGlyZXM6IDIw
NTAtMDEtMDEK
        LIC
      end
    end

    it 'reads from chorus.license' do
      license[:vendor].should == 'custom'
    end
  end

  describe 'workflow_enabled?' do
    before do
      mock(license).[](:vendor) { vendor }
    end

    context 'vendor:alpine' do
      let(:vendor) { 'alpine' }

      it 'returns true' do
        license.workflow_enabled?.should be_true
      end
    end

    context 'vendor:pivotal' do
      let(:vendor) { 'pivotal' }

      it 'returns true' do
        license.workflow_enabled?.should be_true
      end
    end

    context 'vendor:other' do
      let(:vendor) { 'other' }

      it 'returns false' do
        license.workflow_enabled?.should be_false
      end
    end
  end

  describe 'branding' do
    before do
      mock(license).[](:vendor) { vendor }
    end

    context 'vendor:alpine' do
      let(:vendor) { 'alpine' }

      it 'returns alpine' do
        license.branding.should == 'alpine'
      end
    end

    context 'vendor:pivotal' do
      let(:vendor) { 'pivotal' }

      it 'returns pivotal' do
        license.branding.should == 'pivotal'
      end
    end

    context 'vendor:other' do
      let(:vendor) { 'other' }

      it 'returns alpine' do
        license.branding.should == 'alpine'
      end
    end
  end
end
