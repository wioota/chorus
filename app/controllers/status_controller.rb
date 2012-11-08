class StatusController < ApplicationController
  skip_before_filter :require_login

  def show
    render :json => { :status => "Chorus is running" }
  end
end