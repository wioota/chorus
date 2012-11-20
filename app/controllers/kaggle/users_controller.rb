module Kaggle
  class UsersController < ApplicationController
    def index
      users = Kaggle::API.users(:filters => params[:filters])
      users.sort! { |user1, user2| user1['rank'] <=> user2['rank'] }

      present users
    end
  end
end