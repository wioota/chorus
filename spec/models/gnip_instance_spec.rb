require 'spec_helper'

describe GnipInstance do
  describe "validations" do
    it { should validate_presence_of :stream_url }
    it { should validate_presence_of :name }
    it { should validate_presence_of :username }
    it { should validate_presence_of :password }
    it { should validate_presence_of :owner }

    describe "name" do
      context "when gnip instance name is invalid format" do
        it "fails validation when not a valid format" do
          FactoryGirl.build(:gnip_instance, :name => "1aaa1").should_not be_valid
        end

        it "fails validation due to field length" do
          FactoryGirl.build(:gnip_instance, :name => 'a'*65).should_not be_valid
        end

        it "does not fail validation due to field length" do
          FactoryGirl.build(:gnip_instance, :name => 'a'*45).should be_valid
        end
      end

      context "when hadoop instance name is valid" do
        it "validates" do
          FactoryGirl.build(:gnip_instance, :name => "aaa1").should be_valid
        end
      end
    end
  end

  describe "associations" do
    it { should belong_to(:owner).class_name('User') }
    it { should have_many :events }
    it { should have_many :activities }
  end
end