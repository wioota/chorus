require 'spec_helper'

describe KaggleApi do
  describe "users" do
    describe "filtering" do
      it "can filter by greater" do
        users = KaggleApi.users(:filters => ["rank|greater|10"])
        users.length.should == 1
        users.first["KaggleRank"].should > 10
      end

      it "can filter by equal" do
        users = KaggleApi.users(:filters => ["rank|equal|9"])
        users.length.should == 1
        users.first["KaggleRank"].should == 9
      end

      it "can filter by equal on list data" do
        users = KaggleApi.users(:filters => ["past_competition_types|equal|geospatial"])
        users.length.should == 1
        users.first["PastCompetitionTypes"].should include "Geospatial"
      end

      it "ignores blank filter values" do
        users = KaggleApi.users(:filters => ["rank|greater|"])
        users.length.should == 2
      end

      it "ignores blank filter values on list data" do
        users = KaggleApi.users(:filters => ["favorite_technique|includes|"])
        users.length.should == 2
      end

      it "searches software, techniques and location by substring match" do
        users = KaggleApi.users(:filters => ["favorite_technique|includes|svm",
                                 "favorite_software|includes|ggplot2",
                                 "location|includes|SaN FrAnCiScO"])
        users.length.should == 1
        users.first['FavoriteTechnique'].should include "SVM"
        users.first['FavoriteSoftware'].should include "ggplot2"
        users.first['Location'].should include "San Francisco"
      end

      it "doesn't break if you pass in a number" do
        expect {
          KaggleApi.users(:filters => ["favorite_technique|includes|1234"])
        }.to_not raise_error
      end

      it "doesn't break with an invalid key" do
        users = KaggleApi.users(:filters => ["notakey|includes|foo"])
        users.length.should == 0
      end
    end
  end
end