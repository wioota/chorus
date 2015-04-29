class UserImagesController < ImagesController
  before_filter :require_referenced_user, :only => :create
  protected

  def load_entity
    @entity = User.find(params[:user_id])
    @user = @entity
  end

  def authorize_create!
    # Remove this method when 'authorize_create!' is taken out of
    # ImagesController
  end

  def authorize_show!
    true
  end
end
