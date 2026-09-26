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
# Handle Registration views - always linked to a club
class RegistrationsController < ApplicationController
	before_action :load_participation_context
	before_action :load_registration_kind
	before_action :set_registration, only: [ :show, :edit, :update, :terminate ]

	# GET /clubs/x/registrations
	# GET /clubs/x/registrations.json
	def index
		@policy = check_policy!(RegistrationPolicy, club: @club)

		search  = params[:search].presence
		@registrations =
			Registration.search(club: @club, kind: @kind, status: @status, search:)

		title  = prepare_index_title(search)
		page   = paginate(@registrations, 1.2)	# paginate results
		table  = helpers.registrations_table(registrations: page)
		retlnk = path_for(@club)
		create_index(title:, table:, page:, retlnk:)
	end

	# GET /registrations/1
	# GET /registrations/1.json
	def show
		@policy = check_policy!(RegistrationPolicy, record: @registration)
		status = @policy.edit?

		@title = create_fields(
			helpers.participation_title(
				@registration,
				status_url: edit_path_for(@registration, status:),
				just_icon: false
			)
		)
		@kind ||= @registration.kind.to_sym
		@fields = create_fields(helpers.registration_show_fields(@registration))
		@table  = create_table(helpers.registration_history_table(@registration))
		submit  = edit_path_for(@registration) if @policy.update?
		@submit = create_submit(close: :back, retlnk: base_path(@registration), submit:, frame: :modal)
	end

	# GET /registrations/new
	def new
		@policy = check_policy!(RegistrationPolicy, club: @club)
		@registration = Registration.new(club: @club, kind: @kind)
		@registration.build_person
		prepare_form(:create)
	end

	# POST /registrations
	# POST /registrations.json
	def create
		@policy = check_policy!(RegistrationPolicy, club: @club)
		respond_to do |format|
			Registration.transaction do
				@registration = Registration.new(club: @club, kind: @kind)
				@registration.rebuild(registration_params)
				@registration.starts_on = Date.today

				if @registration.save
					format.html do
						redirect_to post_save_path, notice: Registration.msg(:created)
					end

					format.json { render :show, status: :ok, location: post_save_path }
				else
					log_registration_errors
					raise ActiveRecord::Rollback
				end
			end

			unless @registration.persisted? && @registration.errors.empty?
				prepare_form(:create)

				format.html { render :edit, status: :unprocessable_entity }
				format.json { render json: @registration.errors, status: :unprocessable_entity }
			end
		end
	end

	# GET /registrations/1/edit
	def edit
		@policy = check_policy!(RegistrationPolicy, record: @registration)
		prepare_form(:edit)
	end

	# PATCH/PUT /registrations/1
	# PATCH/PUT /registrations/1.json
	def update
		@policy = check_policy!(RegistrationPolicy, record: @registration)

		respond_to do |format|
			Registration.transaction do
				@registration.rebuild(registration_params)

				notice = Registration.msg(@registration.modified? ? :updated : :no_change)
				if @registration.save
					format.html do
						redirect_to path_for(@registration), notice:
					end

					format.json { render :show, status: :ok, location: @registration }
				else
					log_registration_errors
					raise ActiveRecord::Rollback
				end
			end

			unless @registration.persisted? && @registration.errors.empty?
				prepare_form(:edit)

				format.html { render :edit, status: :unprocessable_entity }
				format.json { render json: @registration.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /registrations/1
	# DELETE /registrations/1.json
	def terminate
		authorize @registration

		if @registration.terminate!
			redirect_to post_save_path,
									notice: Registration.msg(:terminated)
		else
			redirect_back fallback_location: post_save_path,
										alert: Registration.msg(:cannot_terminate)
		end
	end

	private
		# wrapper to set return link for CRUD operations
		def post_save_path
			return_path_for(@registration)
		end

		def prepare_index_title(search)
			title   = Registration.label(:plural)
			concept = @kind || :person
			title   = helpers.person_title(title:, icon: { concept:, options: { namespace: "common", size: "50x50" } })
			title << helpers.participation_search_bar(Registration, search_url: club_registrations_path(search:))
		end

		# Prepare a registration form
		def prepare_form(action)
			status_edit = action == :edit && to_boolean(params[:status])

			if status_edit
				m_fields = helpers.participation_status_form_fields(@registration)
			else
				m_fields  = helpers.registration_form_fields(@registration)
				@p_header = create_fields(helpers.registration_form_title(@registration, action))
				@p_fields = create_fields(helpers.person_form_fields(@registration.person))
				@contacts = create_fields(helpers.person_relationships_form(@registration.person))
			end

			@m_fields = create_fields(m_fields)
			@submit   = create_submit
		end

		def log_registration_errors
			Rails.logger.debug @registration.errors.full_messages

			Rails.logger.debug @registration.person.errors.full_messages

			@registration.person.relationships.each do |r|
				Rails.logger.debug r.errors.full_messages
				Rails.logger.debug r.related_person.errors.full_messages if r.related_person
			end
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_registration
			@registration = Registration.find_by_id(params[:id]) unless @registration&.id==params[:id]
			@club   = @registration&.club
			@kind   = @registration&.kind
		end

		def load_registration_kind
			@kind = Registration.kind_catalog.normalize(params[:kind])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def registration_params
			params.require(:registration).permit(
				:person_id,
				:joined_on,
				:left_on,
				:kind,
				:status,
				:notes,
				:rdx,
				person_attributes: [
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

					relationships_attributes: [
						:id,
						:kind,
						:_destroy,

						related_person_attributes: [
							:id,
							:name,
							:surname,
							:phone,
							:email,
							:birthday,
							:dni,
							:female,
							:address
						]
					]
				]
			)
		end
end
