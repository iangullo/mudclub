module TeamsHelper
	# return FieldComponent for team view title
	def team_title_fields(title:, team: nil, cols: nil, search: nil, edit: nil)
		res = title_start(icon: "team.svg", title: title, cols: cols)
		if search
			res << [{kind: "search-collection", key: :season_id, options: Season.real.order(start_date: :desc), value: team ? team.season_id : session.dig('team_filters', 'season_id')}]
		elsif edit and current_user.admin?
			res << [{kind: "select-collection", key: :season_id, options: Season.real, value: team.season_id}]
		else
			res << [{kind: "label", value: team.season.name}]
		end
		res
	end

	# return a GridComponent for the teams given
	def team_grid(teams:, season: nil, add_teams: false)
		if teams
			title = season ? [] : [{kind: "normal", value: I18n.t("season.abbr")}]
			title << {kind: "normal", value: I18n.t("team.single")}
			title << {kind: "normal", value: I18n.t("division.single")}
			title << {kind: "add", url: new_team_path, frame: "modal"} if add_teams
			rows = Array.new
			teams.each { |team|
				row = {url: team_path(team), items: []}
				row[:items] << {kind: "normal", value: team.season.name, align: "center"} unless season
				row[:items] << {kind: "normal", value: team.to_s}
				row[:items] << {kind: "normal", value: team.division.name, align: "center"}
				row[:items] << {kind: "delete", url: row[:url], name: team.to_s} if add_teams
				rows << row
			}
			{title: title, rows: rows}
		else
			nil
		end
	end

	# return HeaderComponent @fields for forms
	def team_form_fields(title:, team:, eligible_coaches:, cols: nil)
		res = team_title_fields(title:, cols:, team:, edit: true)
		res << [{kind: "label", align: "right", value: I18n.t("person.name_a")}, {kind: "text-box", key: :name, value: team.name}]
		res << [{kind: "icon", value: "category.svg"}, {kind: "select-collection", key: :category_id, options: Category.real, value: team.category_id}]
		res << [{kind: "icon", value: "division.svg"}, {kind: "select-collection", key: :division_id, options: Division.real, value: team.division_id}]
		res << [{kind: "icon", value: "location.svg"}, {kind: "select-collection", key: :homecourt_id, options: Location.home, value: team.homecourt_id}]
		res << [{kind: "icon", value: "time.svg"}, {kind: "select-box", key: :rules, options: Category.time_rules, value: team.periods }]
		res << [{kind: "icon", value: "coach.svg"}, {kind: "label", value:I18n.t("coach.many"), class: "align-center"}]
		res << [{kind: "gap"}, {kind: "select-checkboxes", key: :coach_ids, options: eligible_coaches}]
		res
	end

	# return jump links for a team
	def team_links(team:)
		res = [[{kind: "jump", icon: "player.svg", url: roster_team_path(team), label: I18n.t("team.roster"), frame: "modal", align: "center"}]]
		if (current_user.admin? or current_user.is_coach?)
			res.last << {kind: "jump", icon: "target.svg", url: targets_team_path(team), label: I18n.t("target.many"), align: "center"}
			res.last << {kind: "jump", icon: "teamplan.svg", url: plan_team_path(team), label: I18n.t("plan.abbr"), align: "center"}
		end
		res.last << {kind: "jump", icon: "timetable.svg", url: slots_team_path(team), label: I18n.t("slot.many"), frame: "modal", align: "center"}
		if (current_user.admin? or team.has_coach(current_user.person.coach_id))
			res.last << {kind: "edit", url: edit_team_path, size: "30x30", frame: "modal"}
		end
		res << [{kind: "gap"}]
		res
	end
end
