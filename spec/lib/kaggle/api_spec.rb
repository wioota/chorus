require 'spec_helper'

#Test Kaggle User 1
#id: 47822
#email: 2093j0qur890w3ur0@mailinator.com
#Full name: Bruce Banner
#username: bbanner

#Test Kaggle User 2
#id: 51196
#email: jg93904u9fhwe9ry@mailinator.com
#Full name: Tony Stark
#username: tstark

describe Kaggle::API, :kaggle_API => true do
  describe "users" do
    describe "filtering" do
      it "can filter by greater" do
        users = Kaggle::API.users(:filters => ["rank|greater|10"])
        users.length.should == 1
        users.first["KaggleRank"].should > 10
      end

      it "can filter by equal" do
        users = Kaggle::API.users(:filters => ["rank|equal|9"])
        users.length.should == 1
        users.first["KaggleRank"].should == 9
      end

      it "can filter by equal on list data" do
        users = Kaggle::API.users(:filters => ["past_competition_types|equal|geospatial"])
        users.length.should == 1
        users.first["PastCompetitionTypes"].should include "Geospatial"
      end

      it "ignores blank filter values" do
        users = Kaggle::API.users(:filters => ["rank|greater|"])
        users.length.should == 2
      end

      it "ignores blank filter values on list data" do
        users = Kaggle::API.users(:filters => ["favorite_technique|includes|"])
        users.length.should == 2
      end

      it "searches software, techniques and location by substring match" do
        users = Kaggle::API.users(:filters => ["favorite_technique|includes|svm",
                                               "favorite_software|includes|ggplot2",
                                               "location|includes|SaN FrAnCiScO"])
        users.length.should == 1
        users.first['FavoriteTechnique'].should include "SVM"
        users.first['FavoriteSoftware'].should include "ggplot2"
        users.first['Location'].should include "San Francisco"
      end

      it "doesn't break if you pass in a number" do
        expect {
          Kaggle::API.users(:filters => ["favorite_technique|includes|1234"])
        }.to_not raise_error
      end

      it "doesn't break with an invalid key" do
        users = Kaggle::API.users(:filters => ["notakey|includes|foo"])
        users.length.should == 0
      end
    end
  end
  
  describe ".send_message" do
    let(:user_ids) { [63766] }
    let(:api_key) { Chorus::Application.config.chorus['kaggle']['API_key'] }
    let(:params) { {
       "subject" => "some subject",
       "replyTo" => "test@fun.com",
       "htmlBody" => "message body",
       "APIKey" => api_key,
       "userId" => user_ids
    } }

    it "should send a message and return true" do
      VCR.use_cassette('kaggle_message_single', :tag => :filter_kaggle_API_key) do
        described_class.send_message(params).should be_true
      end
    end

    context "with multiple recipients as array" do
      let(:user_ids) { [63766,63767] }

      it "succeeds with two valid ids" do
        VCR.use_cassette('kaggle_message_multiple', :tag => :filter_kaggle_API_key) do
          described_class.send_message(params).should be_true
        end
      end
    end

    context "when the send message fails" do
      let(:user_ids) { [99999999] }
      it "fails with an invalid id" do
        VCR.use_cassette('kaggle_message_single_fail', :tag => :filter_kaggle_API_key) do
          expect {
            described_class.send_message(params)
          }.to raise_exception(Kaggle::API::MessageFailed)
        end
      end

      context "with multiple recipients as array" do
        let(:user_ids) { [63766,99999999] }

        it "fails with one invalid id" do
          VCR.use_cassette('kaggle_message_multiple_fail', :tag => :filter_kaggle_API_key) do
            expect {
              described_class.send_message(params)
            }.to raise_exception(Kaggle::API::MessageFailed)
          end
        end
      end
    end

    context "when the API times out" do
      it "raises a kaggle error" do
        any_instance_of(Net::HTTP) do |http|
          stub(http).request { raise Timeout::Error.new }
        end

        expect {
          described_class.send_message(params)
        }.to raise_exception(Kaggle::API::MessageFailed,
                  'Could not connect to the Kaggle server')
      end
    end
  end
end