class NotesController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  def create
    note_params = params[:note]
    entity_type = note_params[:entity_type]
    entity_id = note_params[:entity_id]
    model = ModelMap.model_from_params(entity_type, entity_id)

    # Create_note_on is an alias for :show, which will eventually be taken care of by scope
    #authorize! :create_note_on, model
    Authority.authorize! :show, model, current_user
    note_params[:body] = sanitize(note_params[:body])

    note = Events::Note.build_for(model, note_params)

    note.save!

    (note_params[:recipients] || []).each do |recipient_id|
      Notification.create!(:recipient_id => recipient_id, :event_id => note.id)
    end

    present note, :status => :created
  end

  def update
    note = Events::Base.find(params[:id])

    Authority.authorize! :update, note, current_user
    #authorize! :update, note
    note.update_attributes!(:body => sanitize(params[:note][:body]))
    present note
  end

  def destroy
    note = Events::Base.find(params[:id])
    #authorize! :destroy, note
    Authority.authorize! :destroy, note, current_user, {:or => :current_user_is_workspace_owner}
    note.destroy
    render :json => {}
  end
end
