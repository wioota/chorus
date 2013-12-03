class SessionsController < ApplicationController
  skip_before_filter :require_login, :except => :show
  skip_before_filter :extend_expiration

  def create
    session_object = Session.create!(params[:session])
    session[:chorus_session_id] = session_object.session_id
    present session_object, :status => :created
  rescue ActiveRecord::RecordInvalid => e
    present_validation_errors e.record.errors, :status => :unauthorized
  end

  def destroy
    current_session.try(:destroy)
    session.clear
    render :json => {:csrf_token => form_authenticity_token}, :status => :ok
  end

  def show
    present current_session
  end
end
