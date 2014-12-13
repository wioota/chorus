class EventsController < ApplicationController

  def index
    events = case params[:entity_type]
             when 'dashboard'
                Events::Base.for_dashboard_of(current_user)
             when 'user'
               ModelMap.
                   model_from_params(params[:entity_type], params[:entity_id]).
                   accessible_events(current_user)
             else
               model = ModelMap.model_from_params(params[:entity_type], params[:entity_id])
               authorize! :show, model
               model.events
             end

    @uevents = events.includes(Events::Base.activity_stream_eager_load_associations)
    @events = @uevents.order('events.id DESC')
    @user = current_user

  end

  def show
    present Events::Base.visible_to(current_user).find(params[:id]), :presenter_options => {:activity_stream => true, :succinct => true}
  end
end
