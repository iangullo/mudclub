class UsersController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    if current_user.present? and current_user.admin?
      @users = User.search(params[:search])
      @fields = header_fields(I18n.t(:l_user_index))
      @fields << [{kind: "text-search", url: users_path}]
      @g_head = grid_header
      @g_rows = grid_rows
    else
      redirect_to "/"
    end
  end

  def show
    if current_user.present? and current_user.admin?
      @user = User.find(params[:id])
      @fields = header_fields(@user.s_name)
      @fields << []
      @fields.last << {kind: "icon", value: "player.svg"} if @user.is_player?
      @fields.last << {kind: "icon", value: "coach.svg"} if @user.is_coach?
      @fields.last << {kind: "icon", value: "key.svg"} if @user.admin?
    else
      redirect_to "/"
    end
  end

  def new
    if current_user.present? and current_user.admin?
      @user = User.new
  		@user.build_person
      @fields = header_fields(I18n.t(:l_user_new), rows: 4, cols: 2)
      @fields << [{kind: "icon", value: "at.svg"}, {kind: "email-box", key: :email, value: I18n.t(:h_email)}]
      @fields << [{kind: "icon", value: "key.svg"}, {kind: "password-box", key: :password, auto: I18n.t(:l_pass)}]
      @fields << [{kind: "icon", value: "key.svg"}, {kind: "password-box", key: :password_confirmation, auto: I18n.t(:l_pass_conf)}]
      @fields << [{kind: "gap"}, {kind: "text", value: I18n.t(:i_pass_conf), cols: 2}]
    else
      redirect_to "/"
    end
  end

  def edit
    if current_user.present? and current_user.admin?
      @roles = user_roles
      @user = User.find(params[:id])
      @header_fields = form_fields(I18n.t(:l_user_edit))
      @user_fields = [
        [{kind: "label", value: I18n.t(:l_role)}, {kind: "select-box", key: :role, options: User.roles.keys.map {|role| [role.titleize,role]}, value: @user.role}],
        [{kind: "label", value: I18n.t(:l_pic)}, {kind: "select-file", key: :avatar}]
      ]
      @person_fields = [
        [{kind: "label", value: I18n.t(:l_id), align: "right"}, {kind: "text-box", key: :dni, size: 8, value: @user.person.dni}, {kind: "gap"}, {kind: "icon", value: "at.svg"}, {kind: "email-box", key: :email, value: @user.person.email}],
				[{kind: "icon", value: "user.svg"}, {kind: "text-box", key: :nick, size: 8, value: @user.person.nick}, {kind: "gap"}, {kind: "icon", value: "phone.svg"}, {kind: "text-box", key: :phone, size: 12, value: @user.person.phone}]
    ]
    else
      redirect_to "/"
    end
  end

  def create
    if current_user.present? and current_user.admin?
      respond_to do |format|
  			@user = build_new_user(params)	# build user
  			if @user.is_duplicate? then
  				format.html { redirect_to @user, notice: t(:user_duplicate) + "'#{@user.s_name}'" }
  				format.json { render :show,  :created, location: @user }
  			else
  				@user.person.save
  				@user.person_id = @user.person.id
  				if @user.save
  					if @user.person.user_id != @user.id
  						@user.person.user_id = @user.id
  						@user.person.save
  					end
  					format.html { redirect_to users_url, notice: t(:user_created) + "'#{@user.s_name}'" }
  					format.json { render :index, status: :created, location: users_url }
  				else
  					format.html { render :new, notice: "#{@user.errors}" }
  					format.json { render json: @user.errors, status: :unprocessable_entity }
  				end
  			end
  		end
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
  				format.html { redirect_to users_url, notice: t(:user_updated) + "'#{@user.s_name}'" }
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
      uname = @user.s_name
      unlink_person
  		@user.destroy
  		respond_to do |format|
  			format.html { redirect_to users_url, notice: t(:user_deleted) + "'#{@user.s_name}'" }
  			format.json { head :no_content }
  		end
    else
      redirect_to "/"
    end
  end

  private

    # return icon and top of HeaderComponent
  	def header_fields(title, icon: "user.svg", rows: 2, cols: nil, size: nil, _class: nil)
  		[[{kind: "header-icon", value: icon, rows: rows, size: size, class: _class}, {kind: "title", value: title, cols: cols}]]
  	end

  	# return HeaderComponent @fields for forms
  	def form_fields(title, rows: 4, cols: 2)
      res = header_fields(title, icon: @user.picture, rows: rows, cols: cols, size: "100x100", _class: "rounded-full")
    	res << [{kind: "label", value: I18n.t(:l_name)}, {kind: "text-box", key: :name, value: @user.person.name}]
      res << [{kind: "label", value: I18n.t(:l_surname)}, {kind: "text-box", key: :surname, value: @user.person.surname}]
  		res << [{kind: "icon", value: "calendar.svg"}, {kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: @user.person.birthday}]
  		res
  	end

    # return header for @categories GridComponent
	  def grid_header
	    res = [
	      {kind: "normal", value: I18n.t(:h_name)},
	      {kind: "normal", value: I18n.t(:a_player), align: "center"},
        {kind: "normal", value: I18n.t(:a_coach), align: "center"},
        {kind: "normal", value: I18n.t(:a_admin), align: "center"}
	    ]
			res << {kind: "add", url: new_user_path, modal: true} if current_user.admin? or current_user.is_coach?
	  end

	  # return content rows for @categories GridComponent
	  def grid_rows
	    res = Array.new
	    @users.each { |user|
	      row = {url: user_path(user), modal: true, items: []}
	      row[:items] << {kind: "normal", value: user.s_name}
        row[:items] << {kind: "icon", value: user.is_player? ? "Yes.svg" : "No.svg", align: "center"}
        row[:items] << {kind: "icon", value: user.is_coach? ? "Yes.svg" : "No.svg", align: "center"}
        row[:items] << {kind: "icon", value: user.admin? ? "Yes.svg" : "No.svg", align: "center"}
	      row[:items] << {kind: "delete", url: row[:url], name: user.s_name} if current_user.admin?
	      res << row
	    }
	    res
	  end

    # re-build existing @user from raw input given by submittal from "new"
  	# return nil if unsuccessful
  	def rebuild_user(params)
      u_data = user_params
      p_data = u_data[:person_attributes]
      @user.email = u_data[:email] ? u_data[:email] : p_data[:email]
      @user.role  = u_data[:role]
      @user.person_id > 0 ? @user.person.reload : @user.build_person
  		@user.person[:dni]     = p_data[:dni]
  		@user.person[:nick]    = p_data[:nick]
  		@user.person[:name]    = p_data[:name]
  		@user.person[:surname] = p_data[:surname]
  		@user.person[:female]  = p_data[:female]
  		@user.person[:email]   = @user.email
  		@user.person[:phone]   = Phonelib.parse(p_data[:phone]).international.to_s
  	end

    # build & prepare a person for a new user
    def build_new_user(params)
      @user                       = User.new(user_params)
      @user.email                 = params.fetch(:user)[:email]
      @user.role                  = params.fetch(:user)[:role]
      @user.password              = params.fetch(:user)[:password]
      @user.password_confirmation = params.fetch(:user)[:password_confirmation]
      @user.build_person
      @user.person.email   = @user.email
      @user.person.name    = @user.email.split("@").first
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
      roles << {name: t(:l_user_show), id: 0}
      roles << {name: t(:a_player), id: 1}
      roles << {name: t(:a_coach), id: 2}
      roles << {name: t(:a_admin), id: 3}
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
