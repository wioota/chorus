class TagsController < ApplicationController
  def index
    tags = if params[:q].present?
             ActsAsTaggableOn::Tag.named_like(params[:q])
           else
             ActsAsTaggableOn::Tag.all
           end

    present paginate(tags.sort_by!{ |tag| tag.name.downcase })
  end
end