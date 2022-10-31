module PlayersHelper
	# return icon and top of Player FieldsComponent
	def player_title_fields(title:, icon: "player.svg", rows: 2, cols: nil, size: nil, _class: nil)
		title_start(icon:, title:, rows:, cols:, size:, _class:)
	end

	# return grid fields for players with obj indicating
	# => nil: for players index
	# => Team: for team roster views
	def player_grid(players:, obj: nil)
		p_index = (obj == nil)
		title = [{kind: "normal", value: I18n.t("player.number"), align: "center"}, {kind: "normal", value: I18n.t("person.name")}, {kind: "normal", value: I18n.t("person.age"), align: "center"}]
		if p_index
			title << {kind: "normal", value: I18n.t("status.active_a"), align: "center"}
			title << {kind: "add", url: new_player_path, frame: "modal"} if current_user.admin? or current_user.is_coach?
		end
		rows = Array.new
		players.each { | player|
			go_back = p_index ? players_path(search: player.s_name) : team_path(obj)
			row     = {url: player_path(player, retlnk: go_back), frame: "modal", items: []}
			row[:items] << {kind: "normal", value: player.number, align: "center"}
			row[:items] << {kind: "normal", value: player.to_s}
			row[:items] << {kind: "normal", value: player.person.age, align: "center"}
			if p_index
				row[:items] << {kind: "icon", value: player.active? ? "Yes.svg" : "No.svg", align: "center"}
				row[:items] << {kind: "delete", url: row[:url], name: player.to_s} if current_user.admin? or current_user.is_coach? and p_index
			end
			rows << row
		}
		return {title: title, rows: rows}
	end

	# FieldsComponent fields to show for a player
	def player_show_fields(player:, team: nil)
		res = player_title_fields(title: I18n.t("player.single"), icon: player.picture, rows: 4, size: "100x100", _class: "rounded-full")
		res << [{kind: "label", value: player.s_name}]
		res << [{kind: "label", value: player.person.surname}]
		res << [{kind: "string", value: player.person.birthday}]
		if team
			res << [{kind: "label", value: I18n.t("calendar.attendance"), cols: 2}]
			res << [{kind: "icon-label", icon: "attendance.svg", value: team.to_s, cols: 2}]
			att = player.attendance(team: team)[:sessions]
			res << [{kind: "label", value: I18n.t("season.abbr"), align: "right"}, {kind: "text", value: att.to_s + "%"}]
			att = player.attendance(team: team, during: "month")[:sessions]
			res << [{kind: "label", value: I18n.t("calendar.month"), align: "right"}, {kind: "text", value: att.to_s + "%"}]
			att = player.attendance(team: team, during: "week")[:sessions]
			res << [{kind: "label", value: I18n.t("calendar.week"), align: "right"}, {kind: "text", value: att.to_s + "%"}]
		else
			res << [{kind: "label", value: I18n.t(player.female ? "sex.fem_a" : "sex.male_a"), align: "center"}, {kind: "string", value: (I18n.t("player.number") + player.number.to_s)}]
			res << [{kind: "label", value: I18n.t(player.active ? "status.active" : "status.inactive"), align: "center"}]
		end
		res
	end

	# return beginning FieldsComponent for Player forms
	def player_form_title(title:, player:, rows: 3, cols: 2)
		res = player_title_fields(title:, icon: player.picture, rows:, cols:, size: "100x100", _class: "rounded-full")
		f_cols = cols>2 ? cols - 1 : nil
		res << [{kind: "label", value: I18n.t("person.name_a")}, {kind: "text-box", key: :name, label: I18n.t("person.name"), value: player.person.name, cols: f_cols}]
		res << [{kind: "label", value: I18n.t("person.surname_a")}, {kind: "text-box", key: :surname, value: player.person.surname, cols: f_cols}]
		res << [{kind: "label-checkbox", label: I18n.t("sex.fem_a"), key: :female, value: player.person.female}, {kind: "icon", value: "calendar.svg"}, {kind: "date-box", key: :birthday, s_year: 1950, e_year: Time.now.year, value: player.person.birthday, cols: f_cols}]
		res
	end

	# return first part of FieldsComponent for Player forms
	def player_form_fields_1(player:, retlnk:)
		[[
			{kind: "label-checkbox", label: I18n.t("status.active"), key: :active, value: player.active},
			{kind: "gap", size: 8}, {kind: "label", value: I18n.t("player.number")},
			{kind: "number-box", key: :number, min: 0, max: 99, size: 3, value: player.number},
			{kind: "hidden", key: :retlnk, value: retlnk}
		]]
	end

	# return second part of FieldsComponent for Player forms
	def player_form_fields_2(avatar:)
		[[{kind: "upload", key: :avatar, label: I18n.t("person.pic"), value: avatar.filename, cols: 5}]]
	end

	# return personal data FieldsComponent for Player forms
	def player_form_person(person:)
		[
			[{kind: "label", value: I18n.t("person.pid_a"), align: "right"}, {kind: "text-box", key: :dni, size: 8, value: person.dni}, {kind: "gap"}, {kind: "icon", value: "at.svg"}, {kind: "email-box", key: :email, value: person.email}],
			[{kind: "icon", value: "user.svg"}, {kind: "text-box", key: :nick, size: 8, value: person.nick}, {kind: "gap"}, {kind: "icon", value: "phone.svg"}, {kind: "text-box", key: :phone, size: 12, value: person.phone}]
		]
	end
end
