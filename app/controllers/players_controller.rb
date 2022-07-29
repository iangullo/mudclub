class PlayersController < ApplicationController
  include Filterable
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :update, :check_reload]
	before_action :set_player, only: [:show, :edit, :update, :destroy]

	# GET /players
	# GET /players.json
	def index
		check_access(roles: [:admin, :coach])
		@players = get_players
		@title   = title_fields(I18n.t("player.many"))
		@title << [{kind: "search-text", key: :search, value: params[:search] ? params[:search] : session.dig('player_filters', 'search'), url: players_path, size: 10}]
		@grid    =  player_grid(players: @players)
		respond_to do |format|
			format.xlsx {
				response.headers['Content-Disposition'] = "attachment; filename=players.xlsx"
			}
			format.html { render :index }
		end
	end

	# GET /players/1
	# GET /players/1.json
	def show
		check_access(roles: [:admin, :coach], obj: @player)
		@fields = title_fields(I18n.t("player.single"), icon: @player.picture, rows: 4, size: "100x100", _class: "rounded-full")
		@fields << [{kind: "label", value: @player.s_name}]
		@fields << [{kind: "label", value: @player.person.surname}]
		@fields << [{kind: "string", value: @player.person.birthday}]
		@fields << [{kind: "label", value: I18n.t(@player.female ? "sex.fem_a" : "sex.male_a"), align: "center"}, {kind: "string", value: (I18n.t("player.number") + @player.number.to_s)}]
		@fields << [{kind: "label", value: I18n.t(@player.active ? "status.active" : "status.inactive"), align: "center"}]
	end

	# GET /players/new
	def new
		check_access(roles: [:admin, :coach])
		@player = Player.new
		@player.build_person
		@fields = form_fields(I18n.t("player.single"), rows: 3, cols: 2)
	end

	# GET /players/1/edit
	def edit
		check_access(roles: [:admin, :coach], obj: @player)
		@title_fields    = form_fields(I18n.t("player.edit"), rows: 3, cols: 3)
		@player_fields_1 = [[{kind: "label-checkbox", label: I18n.t("status.active"), key: :active, value: @player.active}, {kind: "gap", size: 8}, {kind: "label", value: I18n.t("player.number")}, {kind: "number-box", key: :number, min: 0, max: 99, value: @player.number}]]
		@player_fields_2 = [[{kind: "upload", key: :avatar, label: I18n.t("person.pic"), value: @player.avatar.filename, cols: 5}]]
		@person_fields   = [
			[{kind: "label", value: I18n.t("person.pid_a"), align: "right"}, {kind: "text-box", key: :dni, size: 8, value: @player.person.dni}, {kind: "gap"}, {kind: "icon", value: "at.svg"}, {kind: "email-box", key: :email, value: @player.person.email}],
			[{kind: "icon", value: "user.svg"}, {kind: "text-box", key: :nick, size: 8, value: @player.person.nick}, {kind: "gap"}, {kind: "icon", value: "phone.svg"}, {kind: "text-box", key: :phone, size: 12, value: @player.person.phone}]
		]
	end

	# POST /players
	# POST /players.json
	def create
		check_access(roles: [:admin, :coach])
		respond_to do |format|
			@player = rebuild_player(params)	# rebuild player
			if @player.is_duplicate? then
				format.html { redirect_to players_path(search: @player.person.to_s(true)), notice: {kind: "info", message: "#{I18n.t("player.duplicate")} '#{@player.to_s}'"}, data: {turbo_action: "replace"} }
				format.json { render :index, status: :duplicate, location: players_path(search: @player.person.to_s(true)) }
			else
				@player.person.save
				@player.person_id = @player.person.id
				if @player.save
					if @player.person.player_id != @player.id
						@player.person.player_id = @player.id
						@player.person.save
					end
					format.html { redirect_to players_path(search: @player.person.to_s(true)), notice: {kind: "success", message: "#{I18n.t("player.created")} '#{@player.to_s}'"}, data: {turbo_action: "replace"} }
					format.json { render :index, status: :created, location: players_path(search: @player.person.to_s(true)) }
				else
					format.html { render :new }
					format.json { render json: @player.errors, status: :unprocessable_entity }
				end
			end
		end
	end

	# PATCH/PUT /players/1
	# PATCH/PUT /players/1.json
	def update
		check_access(roles: [:admin, :coach], obj: @player)
		respond_to do |format|
			if @player.update(player_params)
				format.html { redirect_to players_path(search: @player.person.to_s(true)), notice: {kind: "success", message: "#{I18n.t("player.updated")} '#{@player.to_s}'"}, data: {turbo_action: "replace"} }
				format.json { render :index, status: :ok, location: players_path(search: @player.person.name) }
			else
				format.html { render :edit }
				format.json { render json: @player.errors, status: :unprocessable_entity }
			end
		end
	end

  # GET /players/import
  # GET /players/import.json
	def import
    check_access(roles: [:admin])
	  Player.import(params[:file])	# added to import excel
	  format.html { redirect_to players_path, notice: {kind: "success", message: "#{I18n.t("player.import")} '#{params[:file].original_filename}'"}, data: {turbo_action: "replace"} }
	end

	# DELETE /players/1
	# DELETE /players/1.json
	def destroy
    check_access(roles: [:admin])
		p_name = @player.to_s
		unlink_person
		@player.destroy
		respond_to do |format|
			format.html { redirect_to players_path, status: :see_other, notice: {kind: "success", message: "#{I18n.t("player.deleted")} '#{p_name}'"}, data: {turbo_action: "replace"} }
			format.json { head :no_content }
		end
	end

	private

		# return icon and top of FieldsComponent
		def title_fields(title, icon: "player.svg", rows: 2, cols: nil, size: nil, _class: nil)
			title_start(icon: icon, title: title, rows: rows, cols: cols, size: size, _class: _class)
		end

		# return FieldsComponent @fields for forms
		def form_fields(title, rows: 3, cols: 2)
			res = title_fields(title, icon: @player.picture, rows: rows, cols: cols, size: "100x100", _class: "rounded-full")
			f_cols = cols>2 ? cols - 1 : nil
			res << [{kind: "label", value: I18n.t("person.name_a")}, {kind: "text-box", key: :name, label: I18n.t("person.name"), value: @player.person.name, cols: f_cols}]
			res << [{kind: "label", value: I18n.t("person.surname_a")}, {kind: "text-box", key: :surname, value: @player.person.surname, cols: f_cols}]
			if f_cols	# i's an edit form
				res << [{kind: "label-checkbox", label: I18n.t("sex.fem_a"), key: :female, value: @player.person.female}, {kind: "icon", value: "calendar.svg"}, {kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: @player.person.birthday, cols: f_cols}]
			end
			res
		end

		# build new @player from raw input given by submittal from "new"
		# return nil if unsuccessful
		def rebuild_player(params)
			p_data  = params.fetch(:player).fetch(:person_attributes)
			@player = Player.new(player_params)
			@player.build_person
			@player.active   = true
			@player.number   = params.fetch(:player)[:number]
      if @player.person_id==0 # not bound to a person yet?
        p_data[:id].to_i > 0 ? @player.person=Person.find(p_data[:id].to_i) : @player.build_person
      else #person is linked, get it
        @user.person.reload
      end
			@player.person[:dni] = p_data[:dni]
			@player.person[:nick] = p_data[:nick]
			@player.person[:name] = p_data[:name]
			@player.person[:surname] = p_data[:surname]
			@player.person[:female] = p_data[:female] ? p_data[:female] : false
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
