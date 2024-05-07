# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# contact email - iangullo@gmail.com.
#
class SlotsController < ApplicationController
	before_action :set_slot, only: [:show, :edit, :update, :destroy]


	# GET /clubs/x/slots or /clubs/x/slots.json
	def index
		@club = Club.find_by_id(@clubid)
		if check_access(obj: @club)
			@locations = Location.search(club_id: @clubid).practice.order(name: :asc)
			@location  = Location.find_by_id(params[:location_id]) || @locations.first
			title      = helpers.slot_title_fields(title: I18n.t("slot.many"))
			title     << helpers.slot_search_bar(u_manager?)
			@fields    = create_fields(title)
			week_view if @location
			@btn_add   = create_button({kind: "add", url: new_slot_path(club_id: @club.id, location_id: @location&.id, season_id: @seasonid), frame: "modal"}) if (u_manager? && !(@season.teams.empty?))
			@submit    = create_submit(close: "back", submit: nil, retlnk: club_path(@club, rdx: @rdx))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /clubs/x/slots/1 or /clubs/x/slots/1.json
	def show
		if check_access(obj: @slot.team.club)
			@title   = create_fields(helpers.slot_title_fields(title: @slot.team.nick, subtitle: @slot.team.season.name))
			@fields  = create_fields(helpers.slot_show_fields)
			@submit  = create_submit(submit: u_manager? ? edit_slot_path(@slot) : nil, frame: u_manager? ? "modal" : nil)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /clubs/x/slots/new
	def new
		@club = Club.find_by_id(@clubid)
		if check_access(obj: @club)
			set_location
			@slot = Slot.new(season_id: @season.id, location_id: @location.id, wday: 1, start: Time.new(2021,8,30,17,00), duration: 90, team_id: 0)
			prepare_form(title: I18n.t("slot.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /clubs/x/slots/1/edit
	def edit
		if check_access(obj: @slot.team.club)
			prepare_form(title: I18n.t("slot.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /clubs/x/slots or /clubs/x/slots.json
	def create
		if check_access(roles: [:manager])
			@slot = Slot.new(start: Time.new(2021,8,30,17,00)) unless @slot
			respond_to do |format|
				@slot.rebuild(slot_params) # rebuild @slot
				retlnk = club_slots_path(@clubid, season_id: @seasonid, location_id: @slot.location_id)
				if @slot.changed?
					if @slot.save # try to store
						a_desc = "#{I18n.t("slot.created")} '#{@slot.to_s}'"
						register_action(:created, a_desc, url: slot_path(@slot), modal: true)
						format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc,"success"), data: {turbo_action: "replace"} }
						format.json { render :index, status: :created, location: @slot }
					else
						prepare_form(title: I18n.t("slot.new"))
						format.html { render :new, status: :unprocessable_entity }
						format.json { render json: @slot.errors, status: :unprocessable_entity }
					end
				else
					format.html { redirect_to retlnk, notice: no_data_notice, data: {turbo_action: "replace"} }
					format.json { render :index, status: :unprocessable_entity, location: retlnk }
				end
			end
		else
			redirect_to slots_path, data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /clubs/x/slots/1 or /clubs/x/slots/1.json
	def update
		if check_access(obj: @slot.team.club)
			respond_to do |format|
				@slot.rebuild(slot_params) # rebuild @slot
				retlnk = club_slots_path(@slot.club, season_id: @seasonid, location_id: @slot.location_id)
				if @slot.changed?
					if @slot.save
						a_desc = "#{I18n.t("slot.updated")} '#{@slot.to_s}'"
						register_action(:updated, a_desc, url: slot_path(@slot), modal: true)
						format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc,"success"), data: {turbo_action: "replace"} }
						format.json { render :index, status: :ok, location: @slot }
					else
						prepare_form(title: I18n.t("slot.edit"))
						format.html { render :edit, status: :unprocessable_entity }
						format.json { render json: @slot.errors, status: :unprocessable_entity }
					end
				else
					format.html { redirect_to retlnk, notice: no_data_notice, data: {turbo_action: "replace"} }
					format.json { render :index, status: :ok, location: retlnk }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# DELETE /clubs/x/slots/1 or /clubs/x/slots/1.json
	def destroy
		if check_access(obj: @slot.team.club)
			s_name = @slot.to_s
			retlnk = club_slots_path(@slot.team.club, season_id: @seasonid, location_id: @slot.location_id)
			@slot.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("slot.deleted")} '#{s_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to retlnk, status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		# Create fresh time_table slices for each timetable row
		def create_slices
			slices  = []
			t_start = Time.utc(2000,1,1,16,00)
			t_end   = Time.utc(2000,1,1,22,30)
			t_hour  = t_start # reset clock
			while t_hour < t_end  # cicle the full day
				slices << {time: t_hour, label: t_hour.min==0 ? (t_hour.hour.to_s.rjust(2,"0") + ":00") : nil, chunks: []}
				t_hour = t_hour + 15.minutes  # 15 min intervals
			end
			slices
		end

		# Create associated gap if needed
		# if t_slot is passed, it needs to be operationg at s_time
		def create_gap(s_time, d_cols, s_slots, t_slot=nil, t_cols=0)
			gap = nil  # no gap yet
			if t_cols < d_cols # only create if we have a wider d_col
				t_time  = s_time
				s_end   = t_slot ? t_slot.ending : s_time + 1.minute
				t_slots = t_slot ? s_slots.excluding(t_slot) : s_slots
				overlap = t_slot ? t_slots.size>0 : false # check overlaps
				gap = {gap: true, rows: 1, cols: d_cols-t_cols} unless overlap  # we will need a gap
			end
			gap
		end

		# CALCULATE HOW MANY cols we need to reserve for this day
		# i.e. overlapping teams in same location/time
		def day_cols(sea_id, loc_id, wday)
			res     = 1
			s_time  = Time.new(2021,9,1,16,0)
			e_time  = Time.new(2021,9,1,22,30)
			t_time  = s_time
			d_slots = Slot.by_wday(wday, @w_slots)
			while t_time < e_time do	# check the full day
				s_count = 0
				d_slots.each { |slot|
					s_count = s_count+1 if slot.at_work?(wday, t_time)
				}
				res     = s_count if s_count > res
				t_time  = t_time + 15.minutes
			end
			res
		end

		# prepare fields to renfeer edit/new slot form
		def prepare_form(title:)
			@fields = create_fields(helpers.slot_form_fields(title:))
			@submit = create_submit
		end

		# prepare valid locations for the slots view
		def set_location
			@locations = Location.search(club_id: @clubid).practice.order(name: :asc)
			loc_id     = get_param(:location_id, objid: true) || @locations.first.id
			@location  = @slot&.location || Location.find_by_id(loc_id)
		end

		# Use callbacks to share common setup or constraints between actions.
		# create the timetable view grid
		# requires that @location & @season defined
		def week_view
			@w_slots = Slot.search({season_id: @season.id, location_id: @location.id})
			@slices  = create_slices # each slice is a hash {time:, label:, chunks:} Chunks are <td>
			@d_cols  = [1]  # day columns
			1.upto(5) { |i|
				@d_cols << {name: I18n.t("calendar.daynames_a")[i], cols: day_cols(@season.id, @location.id, i)}
				d_slots = Slot.by_wday(i, @w_slots) # check only daily slots
				@slices.each { |slice| # create slice chunks for this day
					train   = nil # placeholder chunks
					gap     = nil
					s_slots = Slot.at_time(slice[:time], d_slots) # slots working on this slice
					unless s_slots.empty?
						s_slots.each { |t_slot| # slots working on this slice
							t_cols = t_slot.timecols(@d_cols[i][:cols], w_slots: d_slots)
							t_rows = t_slot.timerows(i, slice[:time])
							if t_slot.start==slice[:time] # slot starts in this slice
								slice[:chunks] << {slot: t_slot, rows: t_rows, cols: t_cols}
								gap = create_gap(slice[:time], @d_cols[i][:cols], s_slots, t_slot, t_cols)
							elsif t_slot.at_work?(i, slice[:time]) # slot running on this space
								gap = create_gap(slice[:time], @d_cols[i][:cols], s_slots, t_slot, t_cols)
							end
						}
					else
						gap = {rows: 1, cols: @d_cols[i][:cols]}
					end
					slice[:chunks] << gap if gap  # insert gap if required
				}
			}
		end

		def set_slot
			@slot = Slot.find_by_id(params[:id].presence) unless @slot&.id == params[:id].presence.to_i
			@club = @slot&.team.club
			@clubid = @club.id
			get_season(obj: @slot)
			set_location
		end

		# Only allow a list of trusted parameters through.
		def slot_params
			params.require(:slot).permit(
				:id,
				:club_id,
				:duration,
				:hour,
				:location_id,
				:min,
				:season_id,
				:start,
				:team_id,
				:wday)
		end
end
