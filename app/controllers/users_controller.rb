class UsersController < ApplicationController
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
  			@user = rebuild_user(params)	# rebuild user
  			if @user.is_duplicate? then
  				format.html { redirect_to @user, notice: 'Ya existía este jugador.'}
  				format.json { render :show,  :created, location: @user }
  			else
  				@user.person.save
  				@user.person_id = @user.person.id
  				if @user.save
  					if @user.person.user_id != @user.id
  						@user.person.user_id = @user.id
  						@user.person.save
  					end
  					format.html { redirect_to users_url, notice: 'Jugador creado.' }
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
    unless current_user.present? and current_user.admin?
      redirect_to "/"
    end
  end

  def edit
    unless current_user.present? and current_user.admin?
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
  			if @user.update(user_params)
  				format.html { redirect_to users_url, notice: 'Jugador actualizado.' }
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
  			format.html { redirect_to users_url, notice: 'Jugador borrado.' }
  			format.json { head :no_content }
  		end
    else
      redirect_to "/"
    end
  end

  private
	# Use callbacks to share common setup or constraints between actions.
	def set_user
		@user = User.find(params[:id])
	end

	# Never trust parameters from the scary internet, only allow the white list through.
	def user_params
		params.require(:user).permit(:id, :number, :active, :avatar, person_attributes: [:id, :dni, :nick, :name, :surname, :birthday, :female, :email, :phone, :user_id], teams_attributes: [:id, :_destroy])
	end

	# build new @user from raw input given by submittal from "new"
	# return nil if unsuccessful
	def rebuild_user(params)
		@user = User.new(user_params)
		@user.build_person
		@user.active = true
		@user.number = params.fetch(:user)[:number]
		p_data= params.fetch(:user).fetch(:person_attributes)
		@user.person[:dni] = p_data[:dni]
		@user.person[:nick] = p_data[:nick]
		@user.person[:name] = p_data[:name]
		@user.person[:surname] = p_data[:surname]
		@user.person[:female] = p_data[:female]
		@user.person[:email] = p_data[:email]
		@user.person[:phone] = Phonelib.parse(p_data[:phone]).international.to_s
		@user.person[:coach_id] = 0
		@user.person[:user_id] = 0
		@user
	end

	# De-couple from associated person
	def unlink_person
		if @user.person.user_id == @user.id
			p = @user.person
			p.user=User.find(0)   # map to empty user
			p.save
			@user.person_id = 0    # map to empty person
    end
	end
end
