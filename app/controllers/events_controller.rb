class EventsController < ApplicationController
  before_action :set_event, only: %i[ show edit update destroy ]

  # GET /events or /events.json
  def index
    if current_user.present?
      @events = Event.search(params)
    else
      redirect_to "/"
    end
  end

  # GET /events/1 or /events/1.json
  def show
    unless current_user.present?
      redirect_to "/"
    end
  end

  # GET /events/new
  def new
    if current_user.present? and (current_user.admin? or @team.has_coach(current_user.person.coach_id))
      @event  = Event.prepare(event_params)
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # GET /events/1/edit
  def edit
    if current_user.present? and (current_user.admin? or @team.has_coach(current_user.person.coach_id))
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # POST /events or /events.json
  def create
    if current_user.present? and (current_user.admin? or @team.has_coach(current_user.person.coach_id))
      @event = Event.prepare(event_params)

      respond_to do |format|
        if @event.save
          format.html { redirect_to @event }
          format.json { render :show, status: :created, location: @event }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @event.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    if current_user.present? and (current_user.admin? or @team.has_coach(current_user.person.coach_id))
      respond_to do |format|
        rebuild_event
        if @event.update(event_params)
          format.html { redirect_to @event }
          format.json { render :show, status: :ok, location: @event }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @event.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    if current_user.present? and (current_user.admin? or @team.has_coach(current_user.person.coach_id))
      erase_links
      @event.destroy
      respond_to do |format|
        format.html { redirect_to events_url }
        format.json { head :no_content }
      end
    else
      redirect_to(current_user.present? ? events_url : "/")
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.fetch(:event, {})
      params.require(:event).permit(:id, :name, :kind, :start_time, :end_time, :team_id, :location_id)
    end
end
