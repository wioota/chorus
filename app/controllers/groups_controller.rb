class GroupsController < ApplicationController
  before_filter :load_group, :only => [:show, :update, :destroy]

  def index
    groups = Group.all
    render :json => groups.to_json
  end

  def create
    group = Group.create(params[:group])
    render :json => group.to_json
  end

  def new

  end

  def edit

  end

  def show
    render :json => @group.to_json
  end

  def update
    @group.update_attributes(params[:group])
    render :json => @group.to_json
  end

  def destroy
    @group.destroy
    render :json => {}
  end

  private

  def load_group
    @group = Group.find(params[:id])
  end
end
