class PermissionsController < ApplicationController
  before_filter :load_permission, :only => [:show, :update, :destroy]

  def index
    permissions = Permission.all
    render :json => permissions.to_json
  end

  def create
    role = Role.find(params[:permission][:role_id])
    permission = role.permissions.create(params[:permission])
    render :json => permission.to_json
  end

  def new

  end

  def edit

  end

  def show
    render :json => @permission.to_json
  end

  def update
    @permission.update_attributes(params[:permission])
    render :json => @permission.to_json
  end

  def destroy
    @permission.destroy
    render :json => {}
  end

  private

  def load_permission
    @permission = Permission.find(params[:id])
  end
end
