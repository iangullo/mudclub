class UsersController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    if current_user.present? and current_user.admin?
      @users = User.search(params[:search])
    else
      redirect_to "/"
    end
  end

  def new
    if current_user.present? and current_user.admin?
      @user = User.new
  		@user.build_person
    else
      redirect_to "/"
    end
  end

  def create
    if current_user.present? and current_user.admin?
      respond_to do |format|
  			@user = build_new_user(params)	# build user
  			if @user.is_duplicate? then
  				format.html { redirect_to @user }
  				format.json { render :show,  :created, location: @user }
  			else
  				@user.person.save
  				@user.person_id = @user.person.id
  				if @user.save
  					if @user.person.user_id != @user.id
  						@user.person.user_id = @user.id
  						@user.person.save
  					end
  					format.html { redirect_to users_url }
  					format.json { render :index, status: :created, location: users_url }
  				else
  					format.html { render :new }
  					format.json { render json: @user.errors, status: :unprocessable_entity }
  				end
  			end
  		end
    else
      redirect_to "/"
    end
  end

  def show
    if current_user.present? and current_user.admin?
      @user = User.find(params[:id])
    else
      redirect_to "/"
    end
  end

  def edit
    if current_user.present? and current_user.admin?
      @roles = user_roles
      @user = User.find(params[:id])
    else
      redirect_to "/"
    end
  end

  def update
    if current_user.present? and current_user.admin?
      respond_to do |format|
        if params[:user][:password].blank?
          params[:user].delete(:password)
          params[:user].delete(:password_confirmation)
        end
        rebuild_user(params)	# rebuild user
  			if @user.update(user_params)
  				format.html { redirect_to users_url }
  				format.json { render :index, status: :ok, location: users_url }
  			else
  				format.html { render :edit }
  				format.json { render json: @user.errors, status: :unprocessable_entity }
  			end
  		end
    else
      redirect_to "/"
    end
  end

  def destroy
    if current_user.present? and current_user.admin?
      unlink_person
  		@user.destroy
  		respond_to do |format|
  			format.html { redirect_to users_url }
  			format.json { head :no_content }
  		end
    else
      redirect_to "/"
    end
  end

  private
	# Use callbacks to share common setup or constraints between actions.
	def set_user
		@user = User.find(params[:id]) unless @user.try(:id)==params[:id]
	end

	# Never trust parameters from the scary internet, only allow the white list through.
	def user_params
		params.require(:user).permit(:id, :email, :role, :password, :password_confirmation, :avatar, :person_id, person_attributes: [:id, :dni, :nick, :name, :surname, :birthday, :female, :email, :phone, :user_id])
	end

	# re-build existing @user from raw input given by submittal from "new"
	# return nil if unsuccessful
	def rebuild_user(params)
    @user.email = params.fetch(:user)[:email]
		p_data= params.fetch(:user).fetch(:person_attributes)
    @user.person_id > 0 ? @user.person.reload : @user.build_person
		@user.person[:dni] = p_data[:dni]
		@user.person[:nick] = p_data[:nick]
		@user.person[:name] = p_data[:name]
		@user.person[:surname] = p_data[:surname]
		@user.person[:female] = p_data[:female]
		@user.person[:email] = @user.email
		@user.person[:phone] = Phonelib.parse(p_data[:phone]).international.to_s
	end

  # build & prepare a person for a new user
  def build_new_user(params)
    @user = User.new(user_params)
    @user.email = params.fetch(:user)[:email]
    @user.password = params.fetch(:user)[:password]
    @user.password_confirmation = params.fetch(:user)[:password_confirmation]
    @user.build_person
    @user.person.email = @user.email
    @user.person.name = @user.email.split("@").first
    @user.person.surname = @user.email.split("@").last
    @user
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

  def user_roles
    roles = Array.new
    roles << {name: "Usuario", id: 0}
    roles << {name: "Jugador", id: 1}
    roles << {name: "Entrenador", id: 2}
    roles << {name: "Admin.", id: 3}
  end
end
