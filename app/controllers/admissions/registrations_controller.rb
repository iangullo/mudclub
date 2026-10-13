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
	before_action :set_registration, except: %i[index new create]

	# GET /clubs/x/registrations
	# GET /clubs/x/registrations.json
	def index
		@policy = check_policy!(RegistrationPolicy, club: @club)

		@registrations =
			if @policy.registration_manager?
				Registration.for_club(@club).order(created_at: :desc)
			else
				Registration.where(submitted_by_id: current_user.person_id).order(created_at: :desc)
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
		@policy = check_policy!(RegistrationPolicy, record: @registration, token: @token)
		@title  = create_fields(helpers.registration_header)
		@kind ||= @registration.kind.to_sym
		@header = create_fields(helpers.registration_show_header(@registration))
		@fields = create_fields(helpers.registration_show_fields(@registration))
		@table  = create_table(helpers.registration_history_table(@registration))
		submit  = edit_path_for(@registration, frame: :modal) if @policy.edit?
		@submit = create_submit(close: nil, retlnk: base_path(@registration), submit:, frame: :modal)
	end

	# GET /registrations/new
	def new
		@policy = check_policy!(RegistrationPolicy, club: @club)
		@registration = Registration.new(club: @club, requested_team_id: @team&.id, kind: @kind)
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
				@registration.submitted_by_id = current_user&.person_id if @registration.requester_kind.to_sym == :other

				if @registration.save
					format.html do
						redirect_to path_for(@registration), notice: Registration.msg(:created)
					end

					format.json { render :show, status: :ok, location: path_for(@registration) }
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
		@policy = check_policy!(RegistrationPolicy, record: @registration, token: @token)
		prepare_form(:edit)
	end

	def update
		@policy = check_policy!(RegistrationPolicy, record: @registration, token: @token)

		respond_to do |format|
			retlnk = path_for(@registration)

			@registration.rebuild(registration_params)

			if @registration.modified?
				if @registration.save
					format.html { redirect_to retlnk, notice: helpers.flash_message(@registration.msg(:updated), "success"), data: { turbo_action: "replace" } }
					format.json { render :show, status: :ok, location: retlnk }
				else
					prepare_form(:edit)
					format.html { render :edit, status: :unprocessable_entity }
					format.json { render json: @registration.errors, status: :unprocessable_entity }
				end
			else
				format.html { redirect_to retlnk, notice: no_data_notice, data: { turbo_action: "replace" } }
				format.json { render :show, status: :ok, location: retlnk }
			end
		end
	end

	# PATCH send_for_review (or re-submit) a registration request
	def send_for_review
		@policy = check_policy!(RegistrationPolicy, record: @registration, token: @token)

		respond_to do |format|
			retlnk = path_for(@registration)
			@registration.send_for_review!
			format.html { redirect_to retlnk, notice: helpers.flash_message(@registration.msg(:sent_for_review), "success"), data: { turbo_action: "replace" } }
			format.json { render :show, status: :ok, location: retlnk }
		end
	end

	# admin review to a registration request
	def review
		@policy = check_policy!(RegistrationPolicy, record: @registration)
		respond_to do |format|
			retlnk = path_for(@registration)
			# TODO: prepare registration review form
		end
	end

	# Ask requester to provide more information
	def request_information
		@policy = check_policy!(RegistrationPolicy, record: @registration)

		respond_to do |format|
			retlnk = path_for(@registration)
			@registration.request_information!
			format.html { redirect_to retlnk, notice: helpers.flash_message(@registration.msg(:updated), "success"), data: { turbo_action: "replace" } }
			format.json { render :show, status: :ok, location: retlnk }
		end
	end

	# Approve the registration request
	def approve
		@policy = check_policy!(RegistrationPolicy, record: @registration)

		respond_to do |format|
			retlnk = return_path_for(@registration)	# sure???
			@registration.approve!
			# TODO: create the required membership/usership/assignments
			# 			notify approval to anonymous token holder or user that raised it
			@registration.anonymize!
			format.html { redirect_to retlnk, notice: helpers.flash_message(@registration.msg(:updated), "success"), data: { turbo_action: "replace" } }
			format.json { render :show, status: :ok, location: retlnk }
		end
	end

	# Reject the registration request
	def reject
		@policy = check_policy!(RegistrationPolicy, record: @registration)

		respond_to do |format|
			retlnk = return_path_for(@registration)
			@registration.reject!
			# TODO: notify rejection to anonymous token holder or user that raised it
			# 			redirect to-... where???
			format.html { redirect_to retlnk, notice: Registration.msg(:rejected), data: { turbo_action: "replace" } }
			format.json { render :index, status: :ok, location: retlnk }
		end
	end

	# Cancel the registration request
	def cancel
		@policy = check_policy!(RegistrationPolicy, record: @registration, token: @token)

		respond_to do |format|
			retlnk = return_path_for(@registration)
			@registration.cancel!
			format.html { redirect_to retlnk, notice: Registration.msg(:deleted), data: { turbo_action: "replace" } }
			format.json { render :index, status: :ok, location: retlnk }
		end
	end

	private
		def log_registration_errors
			Rails.logger.debug @registration.errors.full_messages
			Rails.logger.debug @registration.candidate.errors.full_messages
			Rails.logger.debug @registration.requester&.errors&.full_messages
			Rails.logger.debug @registration.guardian1&.errors&.full_messages
			Rails.logger.debug @registration.guardian2&.errors&.full_messages
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
			@registration.candidate.female = true if @team&.category&.sex == "female"
			@p_header = create_fields(helpers.registration_form_header(action:))
			p_fields  = helpers.person_form_fields(@registration.candidate, mandatory_email: true)
			p_fields[1].last[:mandatory][:unless] = [ "guardians", "requester" ]
			@p_fields = create_fields(p_fields)


			case action
			when :create
				unless current_user
					@registration.build_requester unless @registration.requester
					@r_fields = create_fields(helpers.registration_requester_form_fields(@registration))
				end
				fields = helpers.registration_form_fields(@registration, action:)
			when :edit
				fields = helpers.registration_form_fields(@registration, action:)
				if @registration.requester_other? && @registration.submitted_by_id == nil
					@r_fields = create_fields(helpers.registration_requester_form_fields(@registration))
				end
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

		# Use callbacks to share common setup or constraints between actions.
		def set_registration
			@registration =
				if @token.present?
					Registration.by_access_token(@token).first
				elsif params[:id].present?
					Registration.find_by_id(params[:id]) unless @registration&.id==params[:id]
				end

				raise ActiveRecord::RecordNotFound unless @registration

				@registration.touch_anonymous_access!
				@token ||= @registration.access_token
				@club    = @registration.club
				@team    = @registration.requested_team
				@kind    = @registration.kind
				assert_param_matches!(:club_id, @club)
		end

		def load_registration_context
			@kind ||= Registration.kind_catalog.normalize(params[:kind])
			if params[:registration] && registration_params[:requested_team_id].present?
				@team = Team.find(registration_params[:requested_team_id])
			elsif params[:team_id].present?
				@team ||= Team.find(params[:team_id])
			end
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def registration_params
			@registration_params ||= params.require(:registration).permit(
				:club_id, :team_id, :kind, :requested_team_id, :status,
				:different_requester, :payment_terms, :requester_kind,
				:remarks, :reviewer_id, :rdx,

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
