# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
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
# Managament of MudClub people
class PeopleController < ApplicationController
	include Filterable
	before_action :set_person, only: [ :show, :edit, :update, :destroy ]

	# GET /clubs/x/people
	# GET /clubs/x/people.json
	def index
		if check_access(roles: [ :admin ])
			search  = params[:search].presence || session.dig("person_filters", "search")
			@people = Person.search(search)
			respond_to do |format|
				format.xlsx do
					a_desc = "#{I18n.t("person.export")} 'people.xlsx'"
					register_action(:exported, a_desc)
					response.headers["Content-Disposition"] = "attachment; filename=people.xlsx"
				end
				format.html do
					page   = paginate(@people)	# paginate results
					title  = helpers.person_title(title: Person.label(form: :plural), icon: { concept: "person", options: { namespace: "common", size: "50x50" } })
					title << [ { kind: :search_text, key: :search, value: search, url: people_path(rdx: @rdx) } ]
					table  = helpers.people_table(people: page)
					submit = { kind: :export, url: people_path(club_id: @club.id, format: :xlsx), working: false } if u_admin?
					create_index(title:, table:, page:, retlnk: base_lnk(people_path(rdx: @rdx)), submit:)
					render :index
				end
			end
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /people/1
	# GET /people/1.json
	def show
		if @person && (check_access(obj: @person) || check_access(roles: [ :admin ]))
			@title  = create_fields(helpers.person_show_title(@person))
			@fields = create_fields(helpers.person_show_fields(@person))
			submit  = edit_person_path(@person, club_id: @club.id, team_id: p_teamid, user: p_userid, rdx: @rdx) if u_manager? || u_secretary? || u_personid == @person.id
			@submit = create_submit(close: :close, submit:, frame: "modal")
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /people/new
	def new
		if check_access(roles: [ :admin ])
			@person = Person.new
			prepare_form("new")
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /people/1/edit
	def edit
		if @person && (check_access(obj: @person) || check_access(roles: [ :admin ]))
			prepare_form("edit")
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# POST /people
	# POST /people.json
	def create
		if check_access(roles: [ :admin ])
			respond_to do |format|
				@person = person.new(club_id: @club.id)
				@person.rebuild(person_params)	# rebuild person
				if @person.id == nil then	# it's a new person
					if @person.paranoid_create # person saved to database
						retlnk = cru_return
						a_desc = "#{I18n.t("people.person.messages.created")} '#{@person.s_name}'"
						register_action(:created, a_desc, url: person_path(@person, rdx: 2))
						format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" } }
						format.json { render :show, status: :created, location: retlnk }
					else
						prepare_form("new")
						format.html { render :new }
						format.json { render json: @person.errors, status: :unprocessable_entity }
					end
				else	# duplicate person
					format.html { redirect_to retlnk, notice: helpers.flash_message("#{I18n.t("people.person.messages.duplicated")} '#{@person.s_name}'"), data: { turbo_action: "replace" } }
					format.json { render :show,  :created, location: cru_return }
				end
			end
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# PATCH/PUT /people/1
	# PATCH/PUT /people/1.json
	def update
		if @person && (check_access(obj: @person) || check_access(roles: [ :admin ]))
			retlnk = cru_return
			respond_to do |format|
				@person.rebuild(person_params)
				if @person.modified?	# person has been edited
					if @person.save
						@person.bind_person(save_changes: true) # ensure binding is correct
						a_desc = "#{I18n.t("people.person.messages.updated")} '#{@person.s_name}'"
						register_action(:updated, a_desc, url: person_path(@person, rdx: 2))
						format.html { redirect_to retlnk, notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" } }
						format.json { render :show, status: :ok, location: retlnk }
					else
						prepare_form("edit")
						format.html { render :edit }
						format.json { render json: @person.errors, status: :unprocessable_entity }
					end
				else	# no changes made
					format.html { redirect_to retlnk, notice: no_data_notice, data: { turbo_action: "replace" } }
					format.json { render :show, status: :ok, location: retlnk }
				end
			end
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# GET /people/import
	# GET /people/import.json
	def import
		if check_access(roles: [ :admin ])
			Person.import(params[:file])	# added to import excel
			a_desc = "#{I18n.t("people.messages.imported")} '#{params[:file].original_filename}'"
			register_action(:imported, a_desc, url: people_path(rdx: 2))
			redirect_to people_path(rdx: @rdx), notice: helpers.flash_message(a_desc, "success"), data: { turbo_action: "replace" }
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	# DELETE /people/1
	# DELETE /people/1.json
	def destroy
		# cannot destroy placeholder person (id ==0)
		if check_access(roles: [ :admin ])
			c_name = @person.s_name
			@person.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("people.person.messages.deleted")} '#{c_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to people_path(rdx: @rdx), status: :see_other, notice: helpers.flash_message(a_desc), data: { turbo_action: "replace" } }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: { turbo_action: "replace" }
		end
	end

	private
		# common return link for create/update operations
		def cru_return
			people_path(search: @person&.to_s, rdx: @rdx)
		end

		# prepare form FieldComponents
		def prepare_form(action)
			@title    = create_fields(helpers.person_form_title(@person.person, title: I18n.t("person.#{action}"), icon: @person.picture))
			@fields = create_fields(helpers.person_form_fields(@person.person))
			@submit   = create_submit
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_person
			@person = Person.find_by_id(params[:id]) unless @person&.id==params[:id]&.to_i
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def person_params
			params.require(:person).permit(
				:id,
				:address,
				:avatar,
				:birthday,
				:dni,
				:email,
				:female,
				:id_back,
				:id_front,
				:name,
				:nick,
				:phone,
				:surname,
				:rdx
			)
		end
end
