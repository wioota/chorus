module Kaggle
  class UsersController < ApplicationController
    def index
      begin
        users = Kaggle::API.users(:filters => params[:filters])
      rescue Kaggle::API::NotReachable => e
        present_errors({:message => e.message}, :status => :unprocessable_entity)
        return
      end

      users.sort! { |user1, user2| user1['rank'] <=> user2['rank'] }

      present users
    end
  end
end