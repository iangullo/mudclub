# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
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
module TeamsHelper
	# A Field Component with table for team attendance. obj is the parent object (player/team)
	def team_attendance_table
		# Check that the offline job has produced attendance data
		if (t_att = @team&.attendance)
			title = [
				{ kind: :normal, value: I18n.t("player.number"), align: "center" },
				{ kind: :normal, value: I18n.t("person.name") },
				{ kind: :normal, value: I18n.t("calendar.week"), align: "center" }, { kind: :normal, value: I18n.t("calendar.month"), align: "center" },
				{ kind: :normal, value: I18n.t("season.abbr"), align: "center" }, { kind: :normal, value: I18n.t("match.many") }
			]
			rows = Array.new
			m_tot = []
			@team.players.order(:number).each do |player|
				p_att = player.attendance(team: @team)
				row = { url: player_path(player, team_id: @team.id, rdx: @rdx), frame: "modal", items: [] }
				row[:items] << { kind: :normal, value: player.number, align: "center" }
				row[:items] << { kind: :normal, value: player.s_name }
				row[:items] << { kind: :percentage, value: p_att[:last7], align: "right" }
				row[:items] << { kind: :percentage, value: p_att[:last30], align: "right" }
				row[:items] << { kind: :percentage, value: p_att[:avg], align: "right" }
				row[:items] << { kind: :normal, value: p_att[:matches], align: "center" }
				m_tot << p_att[:matches]
				rows << row
			end
			rows << {
				items: [
					{ kind: :bottom, value: nil },
					{ kind: :bottom, align: "right", value: I18n.t("stat.average") },
					{ kind: :percentage, value: t_att[:sessions][:week], align: "right" },
					{ kind: :percentage, value: t_att[:sessions][:month], align: "right" },
					{ kind: :percentage, value: t_att[:sessions][:avg], align: "right" },
					{ kind: :normal, value: m_tot.sum / m_tot.size, align: "center" }
				]
			}
			return { title:, rows:, chart: t_att[:sessions] }
		end
		nil
	end

	# Fields showing team coaches
	def team_coaches
		g_row = gap_row(cols: 2)
		coaches = [ g_row ]
		unless (c_count = @team.coaches.count) == 0 # only create if there are coaches
			c_icon = symbol_field("coach", { namespace: "sport", size: "30x30", title: I18n.t("coach.many") }, align: "right", class: "align-top", rows: c_count)
			c_first = true
			@team.coaches.each do |coach|
				if u_manager? || u_secretary?
					c_start = button_field({ kind: :link, label: coach.s_name, url: coach_path(coach, team_id: @team.id, rdx: @rdx), b_class: "items-center", d_class: "text-left" })
				else
					c_start = { kind: :string, value: coach.s_name, class: "align-middle text-left" }
				end
				c_contact = { kind: :contact, phone: coach.person.phone }
				coaches << (c_first ? [ c_icon, c_start, c_contact ] : [ c_start, c_contact ])
				c_first = false if c_first
			end
		end
		coaches << g_row
		coaches
	end

	# return HeaderComponent @fields for forms
	def team_form(title:, cols: nil)
		res = team_title(title:, cols:, edit: true)
		res.last << { kind: :hidden, key: :rdx, value: @rdx } if @rdx
		res << [
			symbol_field("user", align: "right"),
			{ kind: :text_box, key: :nick, value: @team.nick, placeholder: I18n.t("team.single"), mandatory: { length: 3 } },
			{ kind: :hidden, key: :club_id, value: @clubid },
			{ kind: :hidden, key: :sport_id, value: (@sport&.id || 1) }	# will need to break this up for multi-sports in future
		]
		res << [
			symbol_field("category", { namespace: "sport" }, align: "right"),
			{ kind: :select_collection, key: :category_id, options: Category.real, value: @team.category_id }
		]
		res << [
			symbol_field("division", { namespace: "sport" }, align: "right"),
			{ kind: :select_collection, key: :division_id, options: Division.real, value: @team.division_id }
		]
		res << [
			symbol_field("home", {}, align: "right"),
			{ kind: :select_collection, key: :homecourt_id, options: Location.search(club_id: @clubid).home, value: @team.homecourt_id }
		]
		unless @eligible_coaches.empty?
			res << [
				symbol_field("coach", { namespace: "sport" }, align: "right"),
				{ kind: :label, value: I18n.t("coach.many"), class: "align-center" }
			]
			res << [ gap_field, { kind: :select_checkboxes, key: :coach_ids, options: @eligible_coaches } ]
		end
		res
	end

	# return a TableComponent for the teams given
	def team_table(teams: @teams, add_teams: false)
		if teams
			pcount = (device != "mobile" && (u_admin? || (user_in_club? && (u_manager? || u_secretary?))))
			title = ((@rdx == 1 || @player || @coach) ? [ { kind: :normal, value: I18n.t("season.abbr") } ] : [])
			title << { kind: :normal, value: I18n.t("team.single") }
			unless device == "mobile"
				title << { kind: :normal, value: I18n.t("category.single") }
				title << { kind: :normal, value: I18n.t("division.single") }
			end
			if pcount
				title << { kind: :normal, value: I18n.t("player.abbr") }
				trow = { url: "#", items: [ gap_field(cols: 2), { kind: :bottom, value: I18n.t("stat.total") } ] }
				tcnt = []	# total players
			end
			if add_teams
				title << button_field({ kind: :add, url: new_team_path(club_id: @clubid, season_id: @seasonid, rdx: @rdx), frame: "modal" })
			end
			rows = Array.new
			teams.each { |team|
				url = (u_clubid == team.club_id ? team_path(team, rdx: @rdx) : request.path)
				row = { url:, items: [] }
				row[:items] << { kind: :normal, value: team.season.name, align: "center" } if @rdx == 1 || @player || @coach
				row[:items] << { kind: :normal, value: team.name }
				unless device == "mobile"
					row[:items] << { kind: :normal, value: team.category.name, align: "center" }
					row[:items] << { kind: :normal, value: team.division.name, align: "center" }
				end
				if pcount
					cnt = team.players.pluck(:id)
					tcnt += cnt
					row[:items] << { kind: :normal, value: cnt.count, align: "center" }
				end
				row[:items] << button_field({ kind: :delete, url: row[:url], name: team.to_s }) if add_teams
				rows << row
			}
			if pcount
				trow[:items] << { kind: :normal, value: tcnt.uniq.count, align: "center" }
				rows << trow
			end
			{ title:, rows: }
		else
			nil
		end
	end

	# return jump links for a team
	def team_links
		if u_manager? || u_coach? || u_secretary?
			res = [ [
				button_field({ kind: :jump, symbol: symbol_hash("player", namespace: @team&.sport&.name), url: roster_team_path(@team, rdx: @rdx), label: I18n.t("team.roster") }, align: "center")
			] ]
			if u_manager? || u_coach?
				res.last << button_field({ kind: :jump, symbol: "target", url: targets_team_path(@team, rdx: @rdx), label: I18n.t("target.many") }, align: "center")
				res.last << button_field({ kind: :jump, symbol: "plan", url: plan_team_path(@team, rdx: @rdx), label: I18n.t("plan.abbr") }, align: "center")
			end
			res.last << button_field({ kind: :jump, symbol: "timetable", url: slots_team_path(rdx: @rdx), label: I18n.t("slot.many"), frame: "modal" }, align: "center")
		else
			res = [ [] ]
		end
		res
	end

	# fields to edit team targets -- REQUIRES form to be passed!!
	def team_targets_form(form)
		[
			[ topcell_field(I18n.t("target.focus.def"), cols: 2) ],
			[ targets_form_partial(form, focus: 2, cols: 2)	],
			ind_col_toprow,
			[
				targets_form_partial(form, aspect: 1, focus: 2),
				targets_form_partial(form, aspect: 2, focus: 2)
			],
			gap_row(),
			[ topcell_field(I18n.t("target.focus.att"), cols: 2) ],
			[ targets_form_partial(form, focus: 1, cols: 2)	],
			ind_col_toprow,
			[
				targets_form_partial(form, aspect: 1, focus: 1),
				targets_form_partial(form, aspect: 2, focus: 1)
			]
		]
	end

	# return team target fields to be shown
	def team_targets_show
		[
			[ topcell_field(I18n.t("target.focus.def"), cols: 2) ],
			[ target_content(@t_d_gen, cols: 2) ],
			ind_col_toprow,
			[ target_content(@t_d_ind), target_content(@t_d_col) ],
			gap_row(cols: 2),
			[ topcell_field(I18n.t("target.focus.att"), cols: 2) ],
			[ target_content(@t_o_gen, cols: 2) ],
			ind_col_toprow,
			[ target_content(@t_o_ind), target_content(@t_o_col) ]
		]
	end

	def team_plan_accordion(form: nil)
		[ [ { kind: :accordion, title: nil, objects: plan_accordion(form:) } ] ]
	end

	# fields for team time-slots view
	def team_slots
		res = [ [
			gap_field,
			symbol_field("timetable", { size: "30x30" }),
			{ kind: :side_cell, value: I18n.t("slot.many"), align: "left" }
		] ]
		@team.slots.order(:wday).each do |slot|
			res << [ gap_field(size: 1), gap_field(size: 1), string_field(slot.to_s) ]
		end
		res << [ gap_field(size: 1), { kind: :icon_label, symbol: "location", label: @team.slots.first.court, cols: 2 } ]
	end

	# return FieldComponent for team view title
	def team_title(title:, cols: nil, search: nil, edit: nil)
		clubid = @club&.id || @clubid || u_clubid
		res = title_start(icon: ((u_clubid != clubid) ? @club&.logo : symbol_hash("team")), title:, cols:)
		if search
			s_id = @team&.season_id || @season&.id || session.dig("team_filters", "season_id")
			res << [ { kind: :search_collection, key: :season_id, options: Season.real.order(start_date: :desc), value: s_id } ]
			res.last.first[:filter] = { key: :club_id, value: clubid }
		elsif edit and u_manager?
			res << [ { kind: :text_box, key: :name, value: @team.name, placeholder: I18n.t("team.single"), mandatory: { length: 3 } } ]
			res << [
				symbol_field("calendar", align: "right"),
				{ kind: :select_collection, key: :season_id, options: Season.real, value: @team.season_id }
			]
			res.last.first[:filter] = { key: :club_id, value: clubid }
		elsif @team
			res += [
				[ { kind: :label, value: @team.category.name } ],
				[ gap_field(size: 0), { kind: :text, value: "#{@team.division.name} (#{@team.season.name})" } ]
			]
		else # player teams index
			res << [ { kind: :subtitle, value: current_user.player.s_name } ]
		end
		res
	end

	private
		# common toprow for ind/col headers
		def ind_col_toprow
			[
				topcell_field(I18n.t("target.aspect.ind_l")),
				topcell_field(I18n.t("target.aspect.col_l"))
			]
		end

		# return html multiline text for strings
		def target_content(targets, form: nil, cols: nil)
			if form
				targets_form_partial(form, month: targets[:month], aspect: targets[:aspect], focus: targets[:focus], cols:)
			else # just view
				tgts = targets[:tgts].map { |tgt| { text: tgt.to_s,	status: tgt.status } }
				{ kind: :targets, class: "border px py align-top", targets: tgts, cols: }
			end
		end

		# target form partial wrapper
		def targets_form_partial(form, month: 0, aspect: 0, focus: 0, cols: nil)
			{
				kind: :partial,
				partial: "targets_form",
				locals: { form:, month:, aspect:, focus: },
				cols:,
				class: "border px py align-top"
			}
		end

		# return accordion for team targets
		def plan_accordion(form: nil)
			plan = Array.new
			@targets.each do |tgts|
				item = {}
				item[:url]     = "#"
				item[:head]    = tgts[:month]
				item[:content] = FieldsComponent.new(plan_month(tgts, form:))
				plan << item
			end
			plan
		end

		def plan_month(tgts, form:)
			lcls  = "text-indigo-900 font-semibold border px py"
			month = tgts[:i]
			[
				[
					gap_field,
					{ kind: :text, value: I18n.t("target.focus.def"), align: "center", class: lcls },
					{ kind: :text, value: I18n.t("target.focus.att"), align: "center", class: lcls }
				],
				[
					{ kind: :side_cell, value: I18n.t("target.aspect.ind_a"), align: "center" },
					target_content({ month:, aspect: 1, focus: 2, tgts: tgts[:t_d_ind] }, form:),
					target_content({ month:, aspect: 1, focus: 1, tgts: tgts[:t_o_ind] }, form:)
				],
				[
					{ kind: :side_cell, value: I18n.t("target.aspect.col_a"), align: "center" },
					target_content({ month:, aspect: 2, focus: 2, tgts: tgts[:t_d_col] }, form:),
					target_content({ month:, aspect: 2, focus: 1, tgts: tgts[:t_o_col] }, form:)
				]
			]
		end
end
