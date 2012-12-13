class TaggingsController < ApplicationController
  def create
    model = Workfile.find(params[:entity_id])
    authorize! :update, model
    model.tag_list = params[:tag_names].join ","
    model.save!
    render :json => {}, :status => :created
  end
end
