class UsersController < ApplicationController
	include Filterable
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_user, only: [:show, :edit, :update, :destroy]

	def index
		check_access(roles: [:admin])
		@users = User.search(params[:search] ? params[:search] : session.dig('user_filters', 'search'))
		@title = helpers.user_title_fields(I18n.t("user.many"))
		@title << [{kind: "search-text", key: :search, value: params[:search] ? params[:search] : session.dig('user_filters', 'search'), url: users_path}]
		@grid  = helpers.user_grid(users: @users)
	end

	def show
		check_access(roles: [:admin], obj: @user)
		@user  = User.find(params[:id])
		@title = helpers.user_show_fields(user: @user)
		@grid  = helpers.team_grid(teams: @user.teams.order(:season_id))
	end

	def new
		check_access(roles: [:admin])
		@user = User.new
		@user.build_person
		prepare_form(I18n.t("user.new"))
	end

	def edit
		check_access(roles: [:admin], obj: @user)
		prepare_form(I18n.t("user.edit"))
	end

	def create
		check_access(roles: [:admin])
		respond_to do |format|
 			@user = User.new
			@user.rebuild(user_params)	# build user
 			if @user.is_duplicate? then
				format.html { redirect_to @user, notice: helpers.flash_message("#{I18n.t("user.duplicate")} '#{@user.s_name}'"), data: {turbo_action: "replace"}}
 				format.json { render :show,  :created, location: @user }
 			else
 				@user.person.save
 				@user.person_id = @user.person.id
 				if @user.save
 					if @user.person.user_id != @user.id
 						@user.person.user_id = @user.id
 						@user.person.save
 					end
 					format.html { redirect_to users_url, notice: helpers.flash_message("#{I18n.t("user.created")} '#{@user.s_name}'","success"), data: {turbo_action: "replace"} }
 					format.json { render :index, status: :created, location: users_url }
 				else
 					format.html { render :new, notice: helpers.flash_message("#{@user.errors}","error") }
 					format.json { render json: @user.errors, status: :unprocessable_entity }
 				end
 			end
 		end
	end

	def update
		check_access(roles: [:admin], obj: @user)
		respond_to do |format|
			if params[:user][:password].blank? or params[:user][:password_confirmation].blank?
				params[:user].delete(:password)
				params[:user].delete(:password_confirmation)
			end
			@user.rebuild(user_params)	# rebuild user
			if @user.save
				format.html { redirect_to users_url, notice: helpers.flash_message("#{I18n.t("user.updated")} '#{@user.s_name}'","success"), data: {turbo_action: "replace"} }
				format.json { render :index, status: :ok, location: users_url }
			else
				format.html { render :edit }
				format.json { render json: @user.errors, status: :unprocessable_entity }
			end
		end
	end

	def destroy
		check_access(roles: [:admin])
		uname = @user.s_name
		unlink_person
		@user.destroy
 		respond_to do |format|
 			format.html { redirect_to users_url, status: :see_other, notice: helpers.flash_message("#{I18n.t("user.deleted")} '#{@user.s_name}'"), data: {turbo_action: "replace"} }
 			format.json { head :no_content }
 		end
	end

	private
		# Prepare user form
		def prepare_form(title)
			@title         = helpers.user_form_title(title:, user: @user)
			@role          = helpers.user_form_role(user: @user)
			@avatar        = helpers.user_form_avatar(user: @user)
			@person_fields = helpers.user_form_person(user: @user)
			@pass_fields   = helpers.user_form_pass(user: @user)
		end

		# De-couple from associated person
		def unlink_person
			if @user.person.try(:user_id)==@user.id
				p = @user.person
				p.user=User.find(0)   # map to empty user
				p.save
				@user.person_id = 0    # map to empty person
			end
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_user
			@user = User.find(params[:id]) unless @user.try(:id)==params[:id]
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def user_params
			params.require(:user).permit(:id, :email, :role, :password, :password_confirmation, :avatar, :person_id, person_attributes: [:id, :dni, :nick, :name, :surname, :birthday, :female, :email, :phone, :user_id])
		end
end
