class TaggingsController < ApplicationController
  MAXIMUM_TAG_LENGTH=100

  def index
    tags = if params[:q].present?
      ActsAsTaggableOn::Tag.named_like(params[:q])
    else
      ActsAsTaggableOn::Tag.all
    end

    present tags
  end

  def create
    model = Workfile.find(params[:entity_id])
    authorize! :update, model

    tag_names = params[:tag_names] || []
    tag_names.each do |tagname|
      raise_validation_error if tagname.length > MAXIMUM_TAG_LENGTH
    end

    model.tag_list = tag_names.uniq(&:downcase).join ","
    model.save!
    render :json => {}, :status => :created
  end

  private

  def raise_validation_error
    raise ApiValidationError.new(:base, :too_long,
                                 {:field => "Tag",
                                  :count => MAXIMUM_TAG_LENGTH })
  end

end
