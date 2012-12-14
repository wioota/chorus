class TaggingsController < ApplicationController
  def create
    model = Workfile.find(params[:entity_id])
    authorize! :update, model
    tag_names = params[:tag_names] || []
    model.tag_list = tag_names.uniq(&:downcase).join ","
    model.save!
    render :json => {}, :status => :created
  end
end
