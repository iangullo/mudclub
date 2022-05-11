class PlayersController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_player, only: [:show, :edit, :update, :destroy]

	# GET /players
	# GET /players.json
	def index
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			@players = get_players
			@fields = header_fields(I18n.t(:l_player_index))
			@fields << [{kind: "search-text", url: players_path}]
			@g_head = grid_header
      @g_rows = grid_rows
			respond_to do |format|
				format.xlsx {
					response.headers['Content-Disposition'] = "attachment; filename=players.xlsx"
				}
				format.html { render :index }
			end
		else
			redirect_to "/"
		end
	end

	# GET /players/1
	# GET /players/1.json
	def show
		if current_user.present? and (current_user.admin? or current_user.is_coach? or current_user.person.player_id==@player.id)
			@fields = header_fields(I18n.t(:l_player_show), rows: 4, size: "100x100", _class: "rounded-full")
			@fields << [{kind: "label", value: @player.s_name}]
			@fields << [{kind: "label", value: @player.person.surname}]
			@fields << [{kind: "string", value: @player.person.birthday}]
			@fields << [{kind: "label", value: I18n.t(@player.active ? :h_active : :h_inactive), align: "center"}, {kind: "string", value: (I18n.t(:a_num) + @player.number.to_s)}]
		else
			redirect_to "/"
		end
	end

	# GET /players/new
	def new
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			@player = Player.new
			@player.build_person
			@fields = form_fields(I18n.t(:l_player_new), rows: 3, cols: 2)
		else
			redirect_to "/"
		end
	end

	# GET /players/1/edit
	def edit
		unless current_user.present? and (current_user.admin? or current_user.is_coach? or current_user.person.player_id==@player.id)
			redirect_to "/"
		end
		@header_fields = form_fields(I18n.t(:l_player_new), rows: 3, cols: 2)
		@player_fields_1 = [[{kind: "label-checkbox", label: I18n.t(:h_active), key: :active, value: @player.active}, {kind: "gap"}, {kind: "label", value: I18n.t(:l_num)}, {kind: "number-box", key: :number, value: @player.number}]]
		@player_fields_2 = [[{kind: "label", value: I18n.t(:l_pic)}, {kind: "select-file", key: :avatar, cols: 5}]]
		@person_fields = [
			[{kind: "label", value: I18n.t(:l_id), align: "right"}, {kind: "text-box", key: :dni, size: 8, value: @player.person.dni}, {kind: "gap"}, {kind: "icon", value: "at.svg"}, {kind: "email-box", key: :email, value: @player.person.email}],
			[{kind: "icon", value: "user.svg"}, {kind: "text-box", key: :nick, size: 8, value: @player.person.nick}, {kind: "gap"}, {kind: "icon", value: "phone.svg"}, {kind: "text-box", key: :phone, size: 12, value: @player.person.phone}]
		]
	end

	# POST /players
	# POST /players.json
	def create
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			respond_to do |format|
				@player = rebuild_player(params)	# rebuild player
				if @player.is_duplicate? then
					format.html { redirect_to @player, notice: t(:player_duplicate) + "'#{@player.to_s}'" }
					format.json { render :show,  :created, location: @player }
				else
					@player.person.save
					@player.person_id = @player.person.id
					if @player.save
						if @player.person.player_id != @player.id
							@player.person.player_id = @player.id
							@player.person.save
						end
						format.html { redirect_to players_url, notice: t(:player_created) + "'#{@player.to_s}'" }
						format.json { render :index, status: :created, location: players_url }
					else
						format.html { render :new }
						format.json { render json: @player.errors, status: :unprocessable_entity }
					end
				end
			end
		else
			redirect_to "/"
		end
	end

	# PATCH/PUT /players/1
	# PATCH/PUT /players/1.json
	def update
		if current_user.present? and (current_user.admin? or current_user.is_coach? or current_user.person.player_id==@player.id)
			respond_to do |format|
				if @player.update(player_params)
					format.html { redirect_to players_url, notice: t(:player_updated) + "'#{@player.to_s}'" }
					format.json { render :index, status: :ok, location: players_url }
				else
					format.html { render :edit }
					format.json { render json: @player.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to "/"
		end
	end

  # GET /players/import
  # GET /players/import.json
	def import
		if current_user.present? and current_user.admin?
			# added to import excel
	    Player.import(params[:file])
	    format.html { redirect_to players_url, notice: t(:player_import) + "'#{params[:file]}'" }
		else
			redirect_to "/"
		end
	end

	# DELETE /players/1
	# DELETE /players/1.json
	def destroy
		if current_user.present? and current_user.admin?
			p_name = @player.to_s
			unlink_person
			@player.destroy
			respond_to do |format|
				format.html { redirect_to players_url, notice: t(:player_deleted) + "'#{p_name}'" }
				format.json { head :no_content }
			end
		else
			redirect_to "/"
		end
	end

	private

		# return icon and top of FieldsComponent
		def header_fields(title, icon: "player.svg", rows: 2, cols: nil, size: nil, _class: nil)
			[[{kind: "header-icon", value: icon, rows: rows, size: size, class: _class}, {kind: "title", value: title, cols: cols}]]
		end

		# return FieldsComponent @fields for forms
		def form_fields(title, rows: 3, cols: 2)
			res = header_fields(title, icon: @player.picture, rows: rows, cols: cols, size: "100x100", _class: "rounded-full")
			f_cols = cols>2 ? cols - 1 : nil
			res << [{kind: "label", value: I18n.t(:l_name)}, {kind: "text-box", key: :name, value: @player.person.name, cols: f_cols}]
			res << [{kind: "label", value: I18n.t(:l_surname)}, {kind: "text-box", key: :surname, value: @player.person.surname, cols: f_cols}]
			if f_cols	# i's an edit form
				res << [{kind: "icon", value: "calendar.svg"}, {kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: @player.person.birthday, cols: f_cols}]
			end
			res
		end

		# return header for @categories GridComponent
    def grid_header
      res = [
				{kind: "normal", value: I18n.t(:a_num), align: "center"},
        {kind: "normal", value: I18n.t(:h_name)},
        {kind: "normal", value: I18n.t(:h_age), align: "center"},
        {kind: "normal", value: I18n.t(:a_active), align: "center"}
      ]
			res << {kind: "add", url: new_player_path, modal: true} if current_user.admin? or current_user.is_coach?
    end

    # return content rows for @categories GridComponent
    def grid_rows
      res = Array.new
      @players.each { |player|
        row = {url: player_path(player), modal: true, items: []}
				row[:items] << {kind: "normal", value: player.number, align: "center"}
        row[:items] << {kind: "normal", value: player.to_s}
        row[:items] << {kind: "normal", value: player.person.age, align: "center"}
        row[:items] << {kind: "icon", value: player.active? ? "Yes.svg" : "No.svg", align: "center"}
        row[:items] << {kind: "delete", url: row[:url], name: player.to_s} if current_user.admin? or current_user.is_coach?
        res << row
      }
      res
    end

		# build new @player from raw input given by submittal from "new"
		# return nil if unsuccessful
		def rebuild_player(params)
			@player = Player.new(player_params)
			@player.build_person
			@player.active = true
			@player.number = params.fetch(:player)[:number]
			p_data= params.fetch(:player).fetch(:person_attributes)
			@player.person[:dni] = p_data[:dni]
			@player.person[:nick] = p_data[:nick]
			@player.person[:name] = p_data[:name]
			@player.person[:surname] = p_data[:surname]
			@player.person[:female] = p_data[:female]
			@player.person[:email] = p_data[:email]
			@player.person[:phone] = Phonelib.parse(p_data[:phone]).international.to_s
			@player.person[:coach_id] = 0
			@player.person[:player_id] = 0
			@player
		end

		# De-couple from associated person
		def unlink_person
			if @player.person.try(:player_id) == @player.id
				p = @player.person
				p.player=Player.find(0)   # map to empty player
				p.save
				@player.person_id = 0    # map to empty person
	    end
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_player
			@player = Player.find(params[:id]) unless @player.try(:id)==params[:id]
		end

		# get player list depending on the search parameter & user role
		def get_players
			if (params[:search] != nil) and (params[:search].length > 0)
				@players = Player.search(params[:search])
			else
				Player.none
			end
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def player_params
			params.require(:player).permit(:id, :number, :active, :avatar, person_attributes: [:id, :dni, :nick, :name, :surname, :birthday, :female, :email, :phone, :player_id], teams_attributes: [:id, :_destroy])
		end
end
