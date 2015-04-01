class PermissionsController < ApplicationController
  before_filter :load_permission, :only => [:show, :update, :destroy]

  def index
    permissions = Permission.all
    render :json => permissions.to_json
  end

  def create
    role = Role.find(params[:permission][:role_id])
    chorus_class = ChorusClass.find(params[:permission][:chorus_class_id])

    permission = Permission.new(params[:permission])
    permission.role = role
    permission.chorus_class = chorus_class

    permission.save

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
    chorus_class = ChorusClass.find(params[:permission][:chorus_class_id])
    @permission.update_attributes(params[:permission])
    @permission.chorus_class = chorus_class
    @permission.save
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
