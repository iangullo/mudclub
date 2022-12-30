# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2023  Iván González Angullo
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
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_slot, only: [:show, :edit, :create, :update, :destroy]


	# GET /slots or /slots.json
	def index
		check_access(roles: [:user])
		@season   = Season.search(params[:season_id])
		@location = params[:location_id] ? Location.find(params[:location_id]) : @season.locations.practice.first
		@title    = helpers.slot_title_fields(title: I18n.t("slot.many"), season: @season)
		@title << [{kind: "gap", size: 1}, {kind: "search-collection", key: :location_id, url: slots_path, options: @season.locations.practice}]
		week_view if @season and @location
	end

	# GET /slots/1 or /slots/1.json
	def show
		check_access(roles: [:user])
		@season = Season.find(params[:season_id]) if params[:season_id]
		@title  = helpers.slot_title_fields(title: I18n.t("slot.many"), season: @season)
	end

	# GET /slots/new
	def new
		check_access(roles: [:admin], returl: slots_url)
		@season   = Season.find(params[:season_id]) if params[:season_id]
		@slot     = Slot.new(season_id: @season ? @season.id : 1, location_id: params[:location_id] ? params[:location_id] : 1, wday: 1, start: Time.new(2021,8,30,17,00), duration: 90, team_id: 0)
		@fields   = helpers.slot_form_fields(title: I18n.t("slot.new"), slot: @slot, season: @season)
	end

	# GET /slots/1/edit
	def edit
		check_access(roles: [:admin], returl: slots_url)
		@season   = Season.find(@slot.season_id)
		@fields   = helpers.slot_form_fields(title: I18n.t("slot.edit"), slot: @slot, season: @season)
	end

	# POST /slots or /slots.json
	def create
		check_access(roles: [:admin], returl: slots_url)
		respond_to do |format|
			@slot.rebuild(slot_params) # rebuild @slot
			if @slot.save # try to store
				format.html { redirect_to @season ? season_slots_path(@season, location_id: @slot.location_id) : slots_url, notice: helpers.flash_message("#{I18n.t("slot.created")} '#{@sot.to_s}'","success"), data: {turbo_action: "replace"} }
				format.json { render :index, status: :created, location: @slot }
			else
				format.html { render :new, status: :unprocessable_entity }
				format.json { render json: @slot.errors, status: :unprocessable_entity }
			end
		end
	end

	# PATCH/PUT /slots/1 or /slots/1.json
	def update
		check_access(roles: [:admin], returl: slots_url)
		respond_to do |format|
			@slot.rebuild(slot_params) # rebuild @slot
			if @slot.save
				format.html { redirect_to @season ? season_slots_path(@season, location_id: @slot.location_id) : slots_url, notice: helpers.flash_message("#{I18n.t("slot.updated")} '#{@slot.to_s}'","success"), data: {turbo_action: "replace"} }
				format.json { render :index, status: :ok, location: @slot }
			else
				format.html { redirect_to edit_slot_path(@slot) }
				format.json { render json: @slot.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /slots/1 or /slots/1.json
	def destroy
		check_access(roles: [:admin], returl: slots_url)
		s_name = @slot.to_s
		@slot.destroy
		respond_to do |format|
			format.html { redirect_to @season ? season_slots_path(@season, location_id: @slot.location_id) : slots_url, status: :see_other, notice: helpers.flash_message("#{I18n.t("slot.deleted")} '#{s_name}'"), data: {turbo_action: "replace"} }
			format.json { head :no_content }
		end
	end

	private
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
						puts s_slots.count
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
					#gap[:wday] = @d_cols[i][:name] if gap
					slice[:chunks] << gap if gap  # insert gap if required
				}
			}
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

		# Use callbacks to share common setup or constraints between actions.
		def set_slot
			@season = Season.find(params[:slot][:season_id]) if params[:slot].try(:season_id)
			@slot   = Slot.find(params[:id]) unless @slot.try(:id)==params[:id]
			@slot   = Slot.new(start: Time.new(2021,8,30,17,00)) unless @slot
		end

		# Only allow a list of trusted parameters through.
		def slot_params
			params.require(:slot).permit(:season_id, :location_id, :team_id, :wday, :start, :duration, :hour, :min)
		end
end
