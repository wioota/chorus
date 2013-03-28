class TaggingsController < ApplicationController
  MAXIMUM_TAG_LENGTH=100
  wrap_parameters :tagging, :exclude => []

  def create
    if params.has_key?(:taggings)
      taggings = params[:taggings].values
    else
      taggings = [params[:tagging]]
    end

    taggings.each do |tagging|
      model = ModelMap.model_from_params(tagging[:entity_type], tagging[:entity_id])
      authorize! :show, model

      tag_names = tagging[:tag_names] || []
      tag_names.each do |tag_name|
        raise_validation_error if tag_name.length > MAXIMUM_TAG_LENGTH
      end

      unique_tag_names = tag_names.uniq(&:downcase).sort

      model.tag_list = unique_tag_names
      model.save!
    end

    render :json => {}, :status => :created
  end

  private

  def raise_validation_error
    raise ApiValidationError.new(:base, :too_long,
                                 {:field => "Tag",
                                  :count => MAXIMUM_TAG_LENGTH })
  end
end
