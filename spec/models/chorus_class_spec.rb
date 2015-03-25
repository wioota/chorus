require 'spec_helper'

describe ChorusClass do
 it { should have_many(:chorus_objects) }
 it { should have_many(:operations) }
 it { should have_many(:permissions) }
end
