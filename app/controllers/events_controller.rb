class EventsController < ApplicationController
  def index
    events = if params[:entity_type] == "dashboard"
       Events::Base.for_dashboard_of(current_user).includes(Events::Base.activity_stream_eager_load_associations)
     elsif params[:entity_type] == "user"
       ModelMap.model_from_params(params[:entity_type], params[:entity_id]).accessible_events(current_user).includes(:actor, :target1, :target2)
     else
       model = ModelMap.model_from_params(params[:entity_type], params[:entity_id])
       authorize! :show, model
       model.events.includes(:actor, :target1, :target2)
     end
    present paginate(events.order("events.id DESC")), :presenter_options => {:activity_stream => true}
  end

  def show
    present Events::Base.visible_to(current_user).find(params[:id]), :presenter_options => {:activity_stream => true}
  end
end
