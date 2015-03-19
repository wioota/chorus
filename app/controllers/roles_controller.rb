class RolesController < ApplicationController
  before_filter :load_role, :only => [:show, :update, :destroy]

  def index
    roles = Role.all
    render :json => roles.to_json
  end

  def create
    role = Role.create(params[:role])
    render :json => role.to_json
  end

  def new

  end

  def edit

  end

  def show
    render :json => @role.to_json
  end

  def update
    @role.update_attributes(params[:role])
    render :json => @role.to_json
  end

  def destroy
    @role.destroy
    render :json => {}
  end

  private

  def load_role
    @role = Role.find(params[:id])
  end
end
