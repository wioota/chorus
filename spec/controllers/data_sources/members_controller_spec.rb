require 'spec_helper'

describe DataSources::MembersController do
  let(:admin) { users(:admin) }
  let(:gpdb_data_source) { data_sources(:owners) }
  let(:instance_owner) { gpdb_data_source.owner }
  let(:shared_instance) { data_sources(:shared) }
  let(:shared_owner) { shared_instance.owner }
  let(:other_user) { FactoryGirl.create :user }

  describe "#index" do
    before do
      log_in instance_owner
    end

    it_behaves_like "an action that requires authentication", :get, :index, :data_source_id => '-1'

    it "succeeds" do
      get :index, :data_source_id => gpdb_data_source.to_param
      response.code.should == "200"
    end

    it "shows list of users" do
      get :index, :data_source_id => gpdb_data_source.to_param
      decoded_response.length.should == gpdb_data_source.accounts.size
    end

    it_behaves_like "a paginated list" do
      let(:params) { {:data_source_id => gpdb_data_source.to_param} }
    end

    generate_fixture "instanceAccountSet.json" do
      get :index, :data_source_id => gpdb_data_source.to_param
    end
  end

  describe "#create" do
    before do
      any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { true } }
    end

    context "when admin" do
      before do
        log_in admin
      end

      it "fails for a shared account instance" do
        post :create, :data_source_id => shared_instance.id, :account => {:db_username => "lenny", :db_password => "secret", :owner_id => shared_owner.id}
        response.should be_not_found
      end

      context "for an individual accounts instance" do
        it "get saved correctly" do
          post :create, :data_source_id => gpdb_data_source.id, :account => {:db_username => "lenny", :db_password => "secret", :owner_id => admin.id}
          response.code.should == "201"
          rehydrated_account = InstanceAccount.find(decoded_response.id)
          rehydrated_account.should be_present
          rehydrated_account.db_username.should == "lenny"
          rehydrated_account.db_password.should == "secret"
          rehydrated_account.owner.should == admin
          rehydrated_account.instance.should == gpdb_data_source
        end
      end
    end

    context "when instance owner" do
      before do
        log_in instance_owner
      end

      it "fails for a shared accounts instance" do
        post :create, :data_source_id => shared_instance.id, :account => {:db_username => "lenny", :db_password => "secret", :owner_id => shared_owner.id}
        response.should be_not_found
      end

      context "for an individual accounts instance" do
        it "get saved correctly" do
          post :create, :data_source_id => gpdb_data_source.id, :account => {:db_username => "lenny", :db_password => "secret", :owner_id => instance_owner.id}
          response.code.should == "201"
          rehydrated_account = InstanceAccount.find(decoded_response.id)
          rehydrated_account.should be_present
          rehydrated_account.db_username.should == "lenny"
          rehydrated_account.db_password.should == "secret"
          rehydrated_account.owner.should == instance_owner
          rehydrated_account.instance.should == gpdb_data_source
        end
      end
    end

    context "when other_user" do
      before do
        log_in other_user
      end

      it "fails for a shared accounts instance" do
        post :create, :data_source_id => shared_instance.id, :account => {:db_username => "lenny", :db_password => "secret", :owner_id => other_user.id}
        response.should be_not_found
      end

      it "fails for an individual accounts instance" do
        post :create, :data_source_id => gpdb_data_source.id, :account => {:db_username => "lenny", :db_password => "secret", :owner_id => other_user.id}
        response.should be_forbidden
      end
    end

    it "does not succeed when credentials are invalid" do
      log_in instance_owner
      any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? {
        false
      } }
      post :create, :data_source_id => gpdb_data_source.id, :account => {:db_username => "lenny", :db_password => "secret", :owner_id => instance_owner.id}
      response.code.should == "422"
    end
  end

  describe "#update" do
    let(:account) { gpdb_data_source.account_for_user(instance_owner) }

    before do
      any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { true } }
    end

    context "when admin" do
      before do
        log_in admin
      end

      it "succeeds" do
        put :update, :data_source_id => gpdb_data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
        response.code.should == "200"

        decoded_response.db_username.should == "changed"
        decoded_response.owner.id.should == instance_owner.id

        rehydrated_account = InstanceAccount.find(decoded_response.id)
        rehydrated_account.db_password.should == "changed"
      end

      it "succeeds, even if instance is shared" do
        gpdb_data_source.update_attribute :shared, true
        put :update, :data_source_id => gpdb_data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
        response.code.should == "200"
      end
    end

    context "when instance owner" do
      before do
        log_in instance_owner
      end

      it "succeeds for user's account" do
        put :update, :data_source_id => gpdb_data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
        response.code.should == "200"

        decoded_response.db_username.should == "changed"
        decoded_response.owner.id.should == instance_owner.id

        rehydrated_account = InstanceAccount.find(decoded_response.id)
        rehydrated_account.db_password.should == "changed"
      end

      it "succeeds for user's account, even if instance is shared" do
        gpdb_data_source.update_attribute :shared, true
        put :update, :data_source_id => gpdb_data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
        response.code.should == "200"
      end

      it "succeeds for other's account" do
        account.update_attribute :owner, other_user
        put :update, :data_source_id => gpdb_data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
        response.code.should == "200"

        decoded_response.db_username.should == "changed"
        decoded_response.owner.id.should == other_user.id

        rehydrated_account = InstanceAccount.find(decoded_response.id)
        rehydrated_account.db_password.should == "changed"
      end
    end

    context "when other_user" do
      before do
        log_in other_user
      end

      context "someone else's account'" do
        it "fails" do
          put :update, :data_source_id => gpdb_data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
          response.should be_forbidden
        end
      end

      context "his own account" do
        before do
          account.owner = other_user
          account.save!
        end

        it "fails" do
          put :update, :data_source_id => gpdb_data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
          response.should be_forbidden
        end
      end
    end

    it "does not succeed when credentials are invalid" do
      log_in instance_owner
      any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { false } }
      put :update, :data_source_id => gpdb_data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
      response.code.should == "422"
    end
  end

  describe "#destroy" do
    before do
      @other_user_account = FactoryGirl.build(:instance_account, :instance => gpdb_data_source, :owner => other_user).tap { |a| a.save(:validate => false) }
    end

    context "when the current user is the instance's owner" do
      before do
        log_in instance_owner
      end

      it "removes the given account" do
        gpdb_data_source.accounts.find_by_owner_id(other_user.id).should_not be_nil
        delete :destroy, :data_source_id => gpdb_data_source.id, :id => @other_user_account.id
        gpdb_data_source.accounts.find_by_owner_id(other_user.id).should be_nil
      end

      it "succeeds" do
        delete :destroy, :data_source_id => gpdb_data_source.id, :id => @other_user_account.id
        response.should be_ok
      end

      context "when there is no account for the given instance and user" do
        it "responds with 'not found'" do
          delete :destroy, :data_source_id => gpdb_data_source.id, :id => 'not_an_id'
          response.should be_not_found
        end
      end
    end

    context "when the current user is not an admin nor the instance's owner" do
      before do
        log_in FactoryGirl.create(:user)
      end

      it "does not remove the account" do
        delete :destroy, :data_source_id => gpdb_data_source.id, :id => @other_user_account.id
        gpdb_data_source.accounts.find_by_owner_id(other_user.id).should_not be_nil
      end

      it "responds with 'forbidden'" do
        delete :destroy, :data_source_id => gpdb_data_source.id, :id => @other_user_account.id
        response.should be_forbidden
      end
    end
  end
end
