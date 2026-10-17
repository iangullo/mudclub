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

	rescue_from ArgumentError, with: :registration_stale_transition

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

		title  = prepare_index_title
		page   = paginate(@registrations, 1.2)	# paginate results
		table  = helpers.registrations_table(page)
		retlnk = path_for(@club)
		create_index(title:, table:, page:, retlnk:)
	end

	# GET /registrations/1
	# GET /registrations/1.json
	def show
		@policy   = check_policy!(RegistrationPolicy, record: @registration, token: @token)

		if @registration.status == "under_review" && @policy.registration_manager?
			redirect_to path_for(@registration, action: :review)
		end

		@title    = create_fields(helpers.registration_header)
		@kind   ||= @registration.kind.to_sym
		@header   = create_fields(helpers.registration_show_header(@registration))
		@fields   = create_fields(helpers.registration_show_fields(@registration))
		messages  = @token ? @registration.messages.for_requester : @registration.messages
		@messages = create_table(helpers.registration_messages_table(messages))
		submit    = edit_path_for(@registration, frame: :modal) if @policy.edit?
		@submit   = create_submit(close: nil, retlnk: parent_path_for(@registration), submit:, frame: :modal)
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

				unless @registration.save
					log_registration_errors
					raise ActiveRecord::Rollback
				end
			end

			unless @registration.persisted? && @registration.errors.empty?
				prepare_form(:create)
				format.html { render :new, status: :unprocessable_entity }
				format.json { render json: @registration.errors, status: :unprocessable_entity }
				next
			end

			snapshot = RegistrationNotifier.capture(@registration)
			RegistrationNotifier.build(:created, snapshot)&.deliver_later

			format.html { redirect_to path_for(@registration), notice: Registration.msg(:created) }
			format.json { render :show, status: :ok, location: path_for(@registration) }
		end
	end

	# GET /registrations/1/edit
	def edit
		@policy = check_policy!(RegistrationPolicy, record: @registration, token: @token)

		prepare_form(:edit)
	end

	def update
		binding.break
		@policy = check_policy!(RegistrationPolicy, record: @registration, token: @token)

		respond_to do |format|
			retlnk    = path_for(@registration)
			@registration.rebuild(registration_params)

			if @registration.modified? && !@registration.save
				prepare_form(:edit)
				format.html { render :edit, status: :unprocessable_entity }
				format.json { render json: @registration.errors, status: :unprocessable_entity }
				return
			end

			submitted = submit_for_review?
			@registration.send_for_review! if submitted

			notice =
				if submitted									then @registration.msg(:sent_for_review)
				elsif @registration.modified?	then @registration.msg(:updated)
				else													no_data_notice
				end

			format.html { redirect_to retlnk, notice: helpers.flash_message(notice, "success"), data: { turbo_action: "replace" } }
			format.json { render :show, status: :ok, location: retlnk }
		end
	end

	# admin review to a registration request
	def review
		@policy = check_policy!(RegistrationPolicy, record: @registration)

		@header   = create_fields(helpers.registration_show_header(@registration))
		@summary  = create_fields(helpers.registration_show_fields(@registration))
		@messages = create_table(helpers.registration_messages_table(@registration.messages.chronological))
		@review   = create_fields(helpers.registration_review_fields(@registration))
		prepare_review_buttons
		@submit = create_submit(submit: nil)
	end

	# Ask requester to provide more information
	def request_information
		@policy = check_policy!(RegistrationPolicy, record: @registration)

		retlnk  = path_for(@registration)
		message = message_body(:message)

		if body.blank?
			respond_to do |format|
				format.html { redirect_to retlnk, alert: Registration.msg(:message_required) }
				format.json { render json: { error: "message required" }, status: :unprocessable_entity }
			end
			return
		end

		snapshot = RegistrationNotifier.capture(@registration)

		Registration.transaction do
			add_registration_message(message)
			@registration.request_information!(actor: current_user)
		end

		RegistrationNotifier.build(:information_requested, snapshot, message:)&.deliver_later

		respond_to do |format|
			format.html { redirect_to retlnk, notice: helpers.flash_message(@registration.msg(:updated), "success"), data: { turbo_action: "replace" } }
			format.json { render :show, status: :ok, location: retlnk }
		end
	end

	# Approve the registration request
	def approve
		@policy = check_policy!(RegistrationPolicy, record: @registration)

		approver = RegistrationApprover.new(@registration, actor: current_user)
		prep     = approver.prepare

		respond_to do |format|
			dispatch_approval(format, approver, prep)
			# Guard clauses to handle errors when Approval does not have a clean match
			rescue RegistrationApprover::PersonMismatch => e
				render_approval_error(format, "#{Person.msg(:mismatch)} - #{e.role}: #{e.fields.join(", ")}", :conflict)
			rescue ActiveRecord::RecordNotFound => e
				render_approval_error(format, Person.msg(:missing), :unprocessable_entity)
			rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
				render_approval_error(format, e.message, :unprocessable_entity)
		end
	end

	# Reject the registration request
	def reject
		@policy = check_policy!(RegistrationPolicy, record: @registration)

		retlnk = index_path_for(@registration)
		reason = message_body(:reason) || Registration.msg(:no_reason_given)

		RegistrationNotifier.wrap(@registration, :rejected, reason:) do
			Registration.transaction do
				add_registration_message(reason)
				@registration.reject!(actor: current_user)
			end
		end

		respond_to do |format|
			format.html { redirect_to retlnk, notice: Registration.msg(:rejected), data: { turbo_action: "replace" } }
			format.json { render :index, status: :ok, location: retlnk }
		end
	end

	# Cancel the registration request
	def cancel
		@policy = check_policy!(RegistrationPolicy, record: @registration, token: @token)

		retlnk = index_path_for(@registration)
		RegistrationNotifier.wrap(@registration, :cancelled) do
			@registration.cancel!
		end

		respond_to do |format|
			format.html { redirect_to retlnk, notice: Registration.msg(:cancelled), data: { turbo_action: "replace" } }
			format.json { render :index, status: :ok, location: retlnk }
		end
	end

	private
		def add_registration_message(body, system: false, visibility: :shared)
			return nil if body.blank?

			@registration.messages.create!(
				author_kind:       system ? :system : reviewer_kind,
				author_assignment: system ? nil : reviewer_assignment,
				visibility:,
				body: body.to_s.strip
			)
		end

		def chosen_merge_with
			params[:person_merge] == "__new__" ? nil : params[:person_merge]
		end

		def commit_approval(format, approver, prep, merge_with)
			result = nil

			RegistrationNotifier.wrap(@registration, :approved) do
				result = approver.commit(prepared: prep[:prepared],
																guardians: prep[:guardians],
																merge_with:)
				{ membership: result.membership.kind_label,
					team:       result.assignment&.team&.name }
			end

			retlnk = path_for(@registration)
			notice = "#{Registration.msg(:approved)} - #{result.person.s_name} (#{result.membership.kind_label})"
			notice += " / #{result.assignment.team.name}" if result.assignment&.team

			format.html { redirect_to retlnk, notice:, data: { turbo_action: "replace" } }
			format.json { render :show, status: :ok, location: retlnk }
		end

		# Route to modal (ambiguous), auto-reuse (exact), or create (none), or
		# second-request commit (operator chose a Person from the modal).
		def dispatch_approval(format, approver, prep)
			return commit_approval(format, approver, prep, chosen_merge_with) if params.key?(:person_merge)
			return render_approval_merge(format, prep) if prep[:resolution].ambiguous?

			merge_with = prep[:resolution].ok? ? prep[:resolution].person : nil
			commit_approval(format, approver, prep, merge_with)
		end

		def log_registration_errors
			Rails.logger.debug @registration.errors.full_messages
			Rails.logger.debug @registration.candidate.errors.full_messages
			Rails.logger.debug @registration.requester&.errors&.full_messages
			Rails.logger.debug @registration.guardian1&.errors&.full_messages
			Rails.logger.debug @registration.guardian2&.errors&.full_messages
		end

		def message_body(msg_param)
			get_param(msg_param).to_s.strip
		end

		def prepare_index_title
			title   = Registration.label(:plural)
			concept = @kind || :person
			helpers.person_title(title:, icon: { concept:, options: { namespace: "common", size: "50x50" } })
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
				@submit = create_submit
				unless current_user
					@registration.build_requester unless @registration.requester
					@r_fields = create_fields(helpers.registration_requester_form_fields(@registration))
				end
			when :edit
				review  = { kind: :action, type: :submit, name: "commit", value: "send_for_review", label: Registration.act(:send_for_review), confirm: Registration.que(:send_for_review) }
				@submit =
					create_submit(close: :cancel, retlnk: path_for(@registration),
						submit: { kind: :save, label: Registration.act(:save_draft) },
						actions: [ review ]
					)
				if @registration.requester_other? && @registration.submitted_by_id == nil
					@r_fields = create_fields(helpers.registration_requester_form_fields(@registration))
				end
			end

			fields            = helpers.registration_form_fields(@registration, action:)
			@fields           = create_fields(fields)
			@guardian1_fields = prepare_guardian(@registration.guardian1, required: true)
			@guardian2_fields = prepare_guardian(@registration.guardian2)
		end

		def prepare_guardian(guardian, required: false)
			create_fields(
				helpers.person_contact_form_fields(guardian || AdmissionPerson.new)
			)
		end

		# for admin review of submitted registrations
		# Just 3 (maximum) buttons to approve/reject/request_information
		def prepare_review_buttons
			@btn_approve = create_button(helpers.registration_button(:approve, data: { turbo_method: :patch }, frame: nil)) if @policy.approve?
			@btn_request = create_button(helpers.registration_button(:request_information)) if @policy.request_information?
			@btn_reject  = create_button(helpers.registration_button(:reject)) if @policy.reject?
		end

		def render_approval_merge(format, prep)
			handle_object_merge(
				format, @registration, prep[:resolution].candidates, {},
				current_person: nil,
				form_url:      approve_registration_path(@registration, token: @token),
				form_method:   :patch
			)
		end

		def render_approval_error(format, message, status)
			format.html { redirect_to path_for(@registration), alert: message }
			format.json { render json: { error: message }, status: status }
		end

		def registration_stale_transition(error)
			return unless @registration
			respond_to do |format|
				format.html { redirect_to path_for(@registration), alert: Registration.msg(:already_processed) }
				format.json { render json: { error: error.message }, status: :conflict }
			end
		end

		# The managing assignment, if the current actor holds one. Nil for admins
		# acting without a club-level assignment.
		def reviewer_assignment
			@policy.managing_club_assignment(@club)
		end

		# The `author_kind` for a staff-authored message: :reviewer when the actor
		# has a managing assignment, :admin otherwise. Never :requester or :system
		# from these controller actions.
		def reviewer_kind
			reviewer_assignment ? :reviewer : :admin
		end

		def submit_for_review?
			params[:commit].to_s == "send_for_review"
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

				@registration.touch_anonymous_access! if @token.present?
				@token ||= @registration.access_token if requester_token?
				@club    = @registration.club
				@team    = @registration.requested_team
				@kind    = @registration.kind
				assert_param_matches!(:club_id, @club)
		end

		def load_registration_context
			@kind   ||= Registration.kind_catalog.normalize(params[:kind])
			@token  ||= registration_params[:token]
			if params[:registration] && registration_params[:requested_team_id].present?
				@team   = Team.find(registration_params[:requested_team_id])
			elsif params[:team_id].present?
				@team ||= Team.find(params[:team_id])
			end
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def registration_params
			@registration_params ||= params.require(:registration).permit(
				:club_id, :team_id, :kind, :requested_team_id, :status,
				:different_requester, :payment_terms, :requester_kind,
				:remarks, :message, :reason, :reviewer_id, :rdx, :token,

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
			)
		end
end
