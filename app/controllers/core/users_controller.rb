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
# Managament of MudClub server users
class UsersController < ApplicationController
	include Filterable
	include PersonBearingController

	before_action :set_user, only: [ :show, :edit, :update, :destroy, :actions, :clear_actions, :anonymize ]

	# GET /users
	# GET /users.json
	def index
		@policy = check_policy!(UserPolicy, club: @club)

		@search = (params[:search].presence || session.dig("user_filters", "search"))
		@users  = User.search(@search, current_user)
		page    = paginate(@users, 1.7)	# paginate results
		title   = helpers.person_title(title: User.label(:plural), icon: { concept: "user", options: { size: "50x50" } })
		title  << [ { kind: :search_text, key: :search, value: @search, url: users_path(rdx: @rdx) } ]
		table   = helpers.user_table(users: page)
		create_index(title:, table:, page:, retlnk: server_path)
	end

	# GET /users/1
	# GET /users/1.json
	def show
		@policy = check_policy!(UserPolicy, record: @user, club: @club)

		@u_acts = scoped_user_actions
		@title  = create_fields(helpers.user_show)
		@roles  = @user.person.memberships.order(joined_on: :desc).order(left_on: :asc)
		@page   = paginate(@roles, 1.2)
		@table  = create_table(helpers.membership_history_table(@page))
		retlnk  = @rdx == 1 ? :back : back_link(default: index_path_for(@user, search: @search))
		submit  = edit_path_for(@user) if @policy.edit?
		actions = []
		if @policy.anonymize? && @user.anonymized_at.nil?
			actions << {
				kind: :anonymize,
				url: anonymize_user_path(@user),
				name: @user.s_name
			}
		end
		@submit = create_submit(close: :back, retlnk:, submit:, actions:, frame: :modal)
	end

	# GET /users/new
	def new
		@policy = check_policy!(UserPolicy, club: @club)

		@user = User.new(locale: current_user.locale)
		@user.build_person
		prepare_form(:new)
	end

	# POST /users
	# POST /users.json
	def create
		@policy = check_policy!(UserPolicy, club: @club)
		@user   = User.new(locale: current_user.locale).tap(&:build_person)

		return reject_missing_password(:new) if password_missing?(user_params)

		save_with_person_merge(
			@user, user_params,
			on_success: ->(user, _) {
				@user = user
				@user.person.update!(user_id: @user.id) if @user.person&.canonical? && @user.person.user_id != @user.id
				notify_and_redirect_user(:created, status: :created)
			},
			on_failure: ->(user, result) {
				@user = user
				respond_to { |format| render_user_errors(:new, format, result) }
			}
		) do |user|
			if user.person&.canonical? && User.where(person_id: user.person.id).where.not(id: user.id).exists?
				user.errors.add(:base, User.msg(:already_exists))
				next false
			end
			user.person.save! if user.person&.new_record?
			true
		end
	end

	# GET /users/1/edit
	def edit
		@policy = check_policy!(UserPolicy, record: @user, club: @club)
		prepare_form(:edit)
	end

	# PATCH/PUT /users/1
	# PATCH/PUT /users/1.json
	def update
		@policy = check_policy!(UserPolicy, record: @user, club: @club)

		if user_params.key?(:password) && password_missing?(user_params)
			return reject_missing_password(:edit)
		end

		save_with_person_merge(
			@user, user_params,
			on_success: ->(user, modified) {
				@user = user
				if modified
					notify_and_redirect_user(:updated)
				else
					respond_saved(
						location: path_for(@user),
						notice: no_data_notice,
						data: { turbo_action: "replace" }
					)
				end
			},
			on_failure: ->(user, result) {
				@user = user
				respond_to { |format| render_user_errors(:edit, format, result) }
			}
		) do |user|
			user.email.present?
		end
	end

	# DELETE /users/1
	# DELETE /users/1.json
	def destroy
		@policy = check_policy!(UserPolicy, record: @user, club: @club)

		a_desc = "#{User.msg(:deleted)} ##{@user.id}"
		retlnk = (@user == current_user) ? root_path : users_path(rdx: @rdx)
		if @user.destroy
			respond_to do |format|
				register_action(:deleted, a_desc)
				format.html { redirect_to retlnk, status: :see_other, notice: helpers.flash_message(a_desc), data: { turbo_action: "replace" } }
				format.json { head :no_content }
			end
		end
	end

	# modal view of User Action log
	def actions
		@policy = check_policy!(UserPolicy, record: @user, club: @club)

		@u_acts  = scoped_user_actions
		@fields  = create_fields(helpers.user_actions_title)
		@actions = create_fields(helpers.user_actions_table)
		@submit  = create_submit(submit: helpers.user_actions_clear, frame: :modal)
	end

	def clear_actions
		@policy = check_policy!(UserPolicy, record: @user, club: @club)

		scoped_club = (!u_admin? && @club) ? @club : nil
		UserAction.clear(@user, club: scoped_club)

		scope_label = scoped_club ? "#{@user.s_name} (#{scoped_club.nick})" : @user.s_name
		a_desc      = "#{I18n.t("user.cleared")} '#{scope_label}'"
		register_action(:deleted, a_desc)

		respond_to do |format|
			format.html { redirect_to path_for(@user), status: :see_other, notice: helpers.flash_message(a_desc), data: { turbo_action: "replace" } }
			format.json { head :no_content }
		end
	end

	# PATCH /users/1/anonymize
	def anonymize
		@policy = check_policy!(UserPolicy, record: @user, club: @club)

		self_erasure = (@user == current_user)

		handle_anonymize(
			@user,
			redirect_url: self_erasure ? root_path : users_path(rdx: @rdx),
			failure_url: path_for(@user)
		) do |user|
			sign_out(user) if self_erasure
		end
	end

	private

		def notify_and_redirect_user(action, status: :ok)
			userview = path_for(@user)
			a_desc   = "#{User.msg(action)} '#{@user.s_name}'"
			register_action(action, a_desc, url: path_for(@user, rdx: 2))
			respond_saved(
				location: userview,
				notice: helpers.flash_message(a_desc, "success"),
				status:,
				data: { turbo_action: "replace" }
			)
		end

		def scoped_user_actions
			scope = @user.user_actions
			scope = scope.for_club(@club) if !u_admin? && @club
			scope.order(updated_at: :desc)
		end

		def password_missing?(attrs)
			attrs[:password].blank? || attrs[:password_confirmation].blank?
		end

		def reject_missing_password(action)
			params[:user]&.delete(:password)
			params[:user]&.delete(:password_confirmation)
			respond_to { |format| render_user_errors(action, format, { message: @user.msg(:no_password) }) }
		end

		def prepare_form(action)
			title     = User.act(action == :new ? :create : action)
			@header   = create_fields(helpers.user_form_title(title:))
			@role     = create_fields(helpers.user_form_role)
			@k_fields = create_fields(helpers.user_form_pass) if action == :new
			@submit   = create_submit
		end

		def render_user_errors(action, format, result = nil)
			render_form_errors(action, format, record: @user, result:, fallback_message: User.val(:none))
		end

		def set_user
			@user   = (User.find_by_id(params[:id]) unless @user&.id == params[:id]) || current_user
			@rdx    = 1 if @user&.id.to_i == current_user&.id
			@search = params[:search].presence || session.dig("user_filters", "search")
		end

		def user_params
			@user_params ||= params.require(:user).permit(
				:id, :avatar, :club_id, :email, :locale, :rdx, :role,
				:password, :password_confirmation, :person_id, :person_merge,
				person_attributes: person_permitted_params(exclude_relationships: true)
			)
		end
end
