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
class UsersController < ApplicationController
	include Filterable
	#skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_user, only: [:show, :edit, :update, :destroy, :actions, :clear_actions]

	# GET /users
	# GET /users.json
	def index
		if check_access(roles: [:admin])
			@users = User.search(params[:search] ? params[:search] : session.dig('user_filters', 'search'))
			title  = helpers.person_title_fields(title: I18n.t("user.many"), icon: "user.svg", size: "50x50")
			title << [{kind: "search-text", key: :search, value: params[:search] ? params[:search] : session.dig('user_filters', 'search'), url: users_path}]
			@title = create_fields(title)
			@grid  = create_grid(helpers.user_grid)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /users/1
	# GET /users/1.json
	def show
		if check_access(roles: [:admin], obj: @user)
			@title  = create_fields(helpers.user_show_fields)
			@role   = create_fields(helpers.user_role_fields)
			@grid   = create_grid(helpers.team_grid(teams: @user.team_list))
			@submit = create_submit(close: "back", close_return: :back, submit: edit_user_path(@user), frame: "modal")
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /users/new
	def new
		if check_access(roles: [:admin])
			@user = User.new
			@user.build_person
			prepare_form(I18n.t("user.new"), create: true)
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# GET /users/1/edit
	def edit
		if check_access(roles: [:admin], obj: @user)
			prepare_form(I18n.t("user.edit"))
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# POST /users.json
	def create
		if check_access(roles: [:admin])
			respond_to do |format|
				@user = User.new
				@user.rebuild(user_params)	# build user
				if @user.modified? then
					if @user.email.presence && @user.paranoid_create
						@user.bind_person(save_changes: true) # ensure binding is correct
						a_desc = "#{I18n.t("user.created")} '#{@user.s_name}'"
						register_action(:created, a_desc, url: user_path(@user))
						format.html { redirect_to users_path, notice: helpers.flash_message(a_desc,"success"), data: {turbo_action: "replace"} }
						format.json { render :index, status: :created, location: users_path }
					else
						prepare_form(I18n.t("user.new"), create: true)
						format.html { render :new, notice: helpers.flash_message("#{@user.errors}","error") }
						format.json { render json: @user.errors, status: :unprocessable_entity }
					end
				else	# no changes to be made
					notice = (@user.persisted? ? "#{I18n.t("user.no_data")} '#{@user.s_name}'" : @user.errors)
					format.html { redirect_to users_path, notice: helpers.flash_message(notice), data: {turbo_action: "replace"}}
					format.json { render :index,  :created, location: users_path }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# PATCH/PUT /users/1
	# PATCH/PUT /users/1.json
	def update
		if check_access(roles: [:admin], obj: @user)
			respond_to do |format|
				if params[:user][:password].blank? or params[:user][:password_confirmation].blank?
					params[:user].delete(:password)
					params[:user].delete(:password_confirmation)
				end
				@user.rebuild(user_params)	# rebuild user
				if @user.modified?
					if @user.email.presence && @user.save
						@user.bind_person(save_changes: true) # ensure binding is correct
						a_desc = "#{I18n.t("user.updated")} '#{@user.s_name}'"
						register_action(:updated, a_desc, url: user_path(@user))
						format.html { redirect_to user_path, notice: helpers.flash_message(a_desc,"success"), data: {turbo_action: "replace"} }
						format.json { render :show, status: :ok, location: user_path }
					else
						prepare_form(I18n.t("user.edit"))
						format.html { render :edit }
						format.json { render json: @user.errors, status: :unprocessable_entity }
					end
				else	# no changes made
					format.html { redirect_to user_path, notice: no_data_notice, data: {turbo_action: "replace"} }
					format.json { render :show, status: :ok, location: user_path }
				end
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# DELETE /users/1
	# DELETE /users/1.json
	def destroy
		if check_access(roles: [:admin])
			uname = @user.s_name
			@user.destroy
			respond_to do |format|
				a_desc = "#{I18n.t("user.deleted")} '#{@user.s_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to users_path, status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# modal view of User Action log
	def actions
		if check_access(roles: [:admin], obj: @user)
			@title  = create_fields(helpers.user_actions_title)
			@actions= create_fields(helpers.user_actions_table)
			@submit = create_submit(submit: helpers.user_actions_clear_fields, frame: "modal")
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	# forget user_actions when reviewed
	def clear_actions
		if check_access(roles: [:admin])
			UserAction.clear(@user)
			respond_to do |format|
				a_desc = "#{I18n.t("user.cleared")} '#{@user.s_name}'"
				register_action(:deleted, a_desc)
				format.html { redirect_to user_path(@user), status: :see_other, notice: helpers.flash_message(a_desc), data: {turbo_action: "replace"} }
				format.json { head :no_content }
			end
		else
			redirect_to "/", data: {turbo_action: "replace"}
		end
	end

	private
		# Prepare user form
		def prepare_form(title, create: nil)
			@title    = create_fields(helpers.person_form_title(@user.person, title:, icon: @user.picture))
			@role     = create_fields(helpers.user_form_role)
			@p_fields = create_fields(helpers.person_form_fields(@user.person))
			if create
				@k_fields = create_fields(helpers.user_form_pass)
			end
			@submit = create_submit
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_user
			@user = User.find_by_id(params[:id]) unless @user&.id==params[:id]
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def user_params
			params.require(:user).permit(
				:id,
				:email,
				:locale,
				:role,
				:password,
				:password_confirmation,
				:avatar,
				:person_id,
				person_attributes: [
					:address,
					:avatar,
					:id,
					:dni,
					:nick,
					:name,
					:surname,
					:birthday,
					:female,
					:email,
					:phone,
					:user_id
				]
			)
		end
end
