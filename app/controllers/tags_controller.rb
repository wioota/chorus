class TagsController < ApplicationController
  def index
    tags = params[:q].present? ? Tag.named_like(params[:q]) : Tag.all
    present paginate(tags.sort_by!{ |tag| tag.name.downcase })
  end

  def destroy
    tag = Tag.find(params[:id])
    tag.destroy

    head :ok
  end
end