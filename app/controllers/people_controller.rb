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
class PeopleController < ApplicationController
	include Filterable
	#skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_person, only: [:show, :edit, :update, :destroy]

	# GET /people
	# GET /people.json
	def index
		if check_access(roles: [:admin])
			@people = get_people
			title   = helpers.person_title_fields(title: I18n.t("person.many"))
			title << [{kind: "search-text", key: :search, value: params[:search] ? params[:search] : session.dig('people_filters','search'), url: people_path}]
			@fields = create_fields(title)
			@grid   = create_grid(helpers.person_grid)
			respond_to do |format|
				format.xlsx {
					a_desc = "#{I18n.t("person.export")} 'people.xlsx'"
					register_action(:exported, a_desc)
					response.headers['Content-Disposition'] = "attachment; filename=people.xlsx"
				}
				format.html { render :index }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /people/1
	# GET /people/1.json
	def show
		if check_access(roles: [:admin], obj: @person)
			fields = helpers.person_show_fields(@person)
			fields[4][0] = {kind: "person-type", user: (@person.user_id > 0), player: (@person.player_id > 0), coach: (@person.coach_id > 0)}
			@fields = create_fields(fields)
			@submit = create_submit(submit: (u_admin? or u_personid==@person.id) ? edit_person_path(@person) : nil, frame: "modal")
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /people/new
	def new
		if check_access(roles: [:admin])
			@person = Person.new(coach_id: 0, player_id: 0)
			prepare_form(title: I18n.t("person.new"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /people/1/edit
	def edit
		if check_access(roles: [:admin], obj: @person)
			prepare_form(title: I18n.t("person.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /people
	# POST /people.json
	def create
		if check_access(roles: [:admin])
			@person = Person.new
			respond_to do |format|
				@person.rebuild(person_params)	# take care of duplicates
				if @person.id	# it was a duplicate
					format.html { redirect_to people_path(search: @person.name), notice: helpers.flash_message("#{I18n.t("person.duplicate")} '#{@person.to_s}'", "success"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :duplicate, location: people_path }
				elsif @person.paranoid_create
					a_desc = "#{I18n.t("person.created")} '#{@person.to_s}'"
					register_action(:created, a_desc, url: person_path(@person), modal: true)
					format.html { redirect_to people_path(search: @person.name), notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: people_path }
				else
					prepare_form(title: I18n.t("person.new"))
					format.html { render :new }
					format.json { render json: @person.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /people/1
	# PATCH/PUT /people/1.json
	def update
		if check_access(roles: [:admin], obj: @person)
			respond_to do |format|
				retlnk = params[:retlnk] ? params[:retlnk] : (@person.id==0 ? "/" : people_path(search: @person.name))
				@person.rebuild(person_params)
				if @person.changed?
					if @person.save
						if @person.id==0 # just edited the club identity
							a_desc = "'#{@person.nick}' #{I18n.t("status.saved")}"
						else
							a_desc = "#{I18n.t("person.updated")} '#{@person.to_s}'"
						end
						register_action(:updated, a_desc, url: person_path(@person), modal: true)
						format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
						format.json { render :index, status: :created, location: retlnk }
					else
						prepare_form(title: I18n.t("person.edit"))
						format.html { render :edit }
						format.json { render json: @person.errors, status: :unprocessable_entity }
					end
				elsif @person.id != 0
					format.html { redirect_to retlnk, notice: no_data_notice, data: {turbo_action: "replace"}}
					format.json { redirect_to retlnk, status: :ok, location: retlnk }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /people/import
	# GET /people/import.json
	def import
		if check_access(roles: [:admin])
			Person.import(params[:file]) # added to import excel
			a_desc = "#{I18n.t("person.import")} '#{params[:file].original_filename}'"
			register_action(:imported, a_desc, url: people_path)
			format.html { redirect_to people_path, notice: helpers.flash_message(a_desc, "success"), data: {turbo_action: "replace"} }
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# DELETE /people/1
	# DELETE /people/1.json
	def destroy
		if check_access(roles: [:admin])
			@person.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("person.deleted")} '#{@person.to_s}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to people_path, status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		# prepare form FieldComponents
		def prepare_form(title:)
			@title   = create_fields(helpers.person_form_title(@person, title:))
			@fields  = create_fields(helpers.person_form_fields(@person))
			@submit  = create_submit
		end

		def set_person
			 @person = Person.find_by_id(params[:id]) unless @person&.id==params[:id]
		end

		# get player list depending on the search parameter & user role
		def get_people
			if (params[:search] != nil) and (params[:search].length > 0)
				Person.search(params[:search])
			else
				Person.none
			end
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def person_params
			params.require(:person).permit(
				:id,
				:address,
				:birthday,
				:dni,
				:email,
				:female,
				:name,
				:nick,
				:phone,
				:surname,
				:player_id,
				:coach_id,
				:user_id
			)
		end
end
