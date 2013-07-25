require 'spec_helper'

describe Job do
  describe 'validations' do
    it { should validate_presence_of :name }
    it { should validate_presence_of :interval_unit }
    it { should validate_presence_of :interval_value }
    it { should ensure_inclusion_of(:interval_unit).in_array(Job.valid_interval_units) }
    it { should have_many :job_tasks }
    
    
    describe "name uniqueness validation" do
      let(:workspace) { workspaces(:public) }
      let(:other_workspace) { workspaces(:private) }
      let(:existing_job) { workspace.jobs.first! }

      it "is invalid if a job in the workspace has the same name" do
        new_job = FactoryGirl.build(:job, :name => existing_job.name, :workspace => workspace)
        new_job.should_not be_valid
        new_job.should have_error_on(:name)
      end

      it "enforces uniqueness only among non-deleted jobs" do
        existing_job.destroy
        new_job = FactoryGirl.build(:job, :name => existing_job.name, :workspace => workspace)
        new_job.should be_valid
      end

      it "is valid if a job in another workspace has the same name" do
        new_job = FactoryGirl.build(:job, :name => existing_job.name, :workspace => other_workspace)
        new_job.should be_valid
      end

      it "is invalid if you change a name to an existing name" do
        new_job = FactoryGirl.build(:job, :name => 'totally_unique', :workspace => workspace)
        new_job.should be_valid
        new_job.name = existing_job.name
        new_job.should_not be_valid
      end
    end
  end

  describe '#create!' do
    let(:attrs) { FactoryGirl.attributes_for(:job) }

    it "is disabled by default" do
      job = Job.create! attrs
      job.should_not be_enabled
    end
  end
end
