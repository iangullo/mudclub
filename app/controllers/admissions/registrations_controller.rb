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
	before_action :load_registration_context
	before_action :set_registration, only: [ :show, :edit, :update, :terminate ]

	# GET /clubs/x/registrations
	# GET /clubs/x/registrations.json
	def index
		@policy = check_policy!(RegistrationPolicy, club: @club)

		@registrations =
			if @policy.registration_manager?
				Registration.for_club(@club).order(created_at: :desc)
			else
				Registration.for_person(current_user.person).order(created_at: :desc)
			end

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
		status  = @policy.edit?

		@header = create_fields(
			helpers.participation_title(
				@registration,
				status_url: edit_path_for(@registration, status:),
				just_icon: false
			)
		)
		@kind ||= @registration.kind.to_sym
		@fields = create_fields(helpers.registration_show_fields(@registration))
		@table  = create_table(helpers.registration_history_table(@registration))
		submit  = edit_path_for(@registration) if @policy.edit?
		@submit = create_submit(close: :back, retlnk: base_path(@registration), submit:, frame: :modal)
	end

	# GET /registrations/new
	def new
		@policy = check_policy!(RegistrationPolicy, club: @club)
		@registration = Registration.new(club: @club, requested_team_id: @team&.id, kind: @kind, requester_kind: :self)
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
			@registration.build_candidate unless @registration.candidate
			@p_header = create_fields(helpers.registration_form_header(action:))
			p_fields  = helpers.person_form_fields(@registration.candidate, mandatory_email: true)
			p_fields[1].last[:mandatory][:unless] = [ "guardians", "requester" ]
			@p_fields = create_fields(p_fields)

			case action
			when :create
				@registration.build_requester
				@r_fields = create_fields(helpers.registration_requester_form_fields(@registration))
				fields    = helpers.registration_form_fields(@registration, action:)
			when :edit
				fields = to_boolean(params[:status]) ?
					helpers.registration_status_form_fields(@registration) :
					helpers.registration_form_fields(@registration, action:)
			end

			@fields = create_fields(fields)

			@guardian1_fields = create_fields(
				helpers.person_contact_form_fields(@registration.guardian1 || AdmissionPerson.new, required: true)
			)
			@guardian2_fields = create_fields(
				helpers.person_contact_form_fields(@registration.guardian2 || AdmissionPerson.new)
			)
			@submit = create_submit
		end

		def log_registration_errors
			Rails.logger.debug @registration.errors.full_messages
			Rails.logger.debug @registration.candidate.errors.full_messages
			Rails.logger.debug @registration.requester&.errors&.full_messages
			Rails.logger.debug @registration.guardian1&.errors&.full_messages
			Rails.logger.debug @registration.guardian2&.errors&.full_messages
		end


		# Use callbacks to share common setup or constraints between actions.
		def set_registration
			@registration = Registration.find_by_id(params[:id]) unless @registration&.id==params[:id]
			@club   = @registration&.club
			@team   = @registration&.team
			@kind   = @registration&.kind
		end

		def load_registration_context
			@kind ||= Registration.kind_catalog.normalize(params[:kind])
			if params[:registration] && registration_params[:requested_team_id].present?
				@team = Team.find(registration_params[:requested_team_id])
			else
				@team ||= Team.find(params[:team_id])
			end
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def registration_params
			params.require(:registration).permit(
				:token, :club_id, :team_id, :kind, :requested_team_id, :status,
				:remarks, :different_requester, :payment_terms, :requester_kind,
				:reviewer_id, :rdx,

				candidate_attributes: [
					:id, :avatar, :name, :nick, :surname,
					:dni, :id_back, :id_front, :female,
					:birthday, :address, :email, :phone
				],

				guardian1_attributes: [ :id, :name, :surname, :email, :phone ],
				guardian2_attributes: [ :id, :name, :surname, :email, :phone ],
				requester_attributes: [ :id, :name, :surname, :email, :phone ],
=begin
				documents_attributes: [
					:id, :kind, :title, :summary, :remarks, :file, :verified, :active
				],
=end
				messages_attributes: [
					:id, :author_kind, :author_assignment_id, :body, :visibility
				]
			)
		end
end
