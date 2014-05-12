require 'spec_helper'

describe PgSchema do

  describe '#class_for_type' do
    let(:schema) { schemas(:pg) }

    it 'should return GpdbTable and GpdbView correctly' do
      schema.class_for_type('r').should == PgTable
      schema.class_for_type('v').should == PgView
    end
  end

end
