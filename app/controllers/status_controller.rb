class StatusController < ApplicationController
  skip_before_filter :require_login

  def show
    render :nothing => true
  end
end