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
module EventsHelper
	# FieldComponents for event attendance
	def event_attendance_title
		res = title_start(icon: symbol_hash("attendance"), title: @event.team.nick, subtitle: @event.team.category.name)
		res[0] << gap_field
		res[1] << gap_field
		event_top_right(res:)
		res << [ gap_field(size: 0), string_field(@event.team.division.name + " (#{@event.team.season.name})", cols: 5, align: "left") ]
		res << gap_row(cols: 6)
	end

	# FieldComponents to show an attendance form
	def event_attendance_form
		res = [ [
			gap_field(size: 2),
			{ kind: :side_cell, value: I18n.t(@event.match? ? "match.roster" : "calendar.attendance"), align: "left" }
		] ]
		res << [
			gap_field(size: 2),
			{ kind: :select_checkboxes, key: :player_ids, options: @event.team.players.order(:number) }
		]
		res << [ { kind: :hidden, key: :rdx, value: @rdx } ] if @rdx
		res << [ { kind: :hidden, key: :team_id, value: @teamid } ] if @teamid
		res
	end

	# return a fields to show a copy event form
	def event_copy
		res = event_title(form: true, teams: @teams)
		res.last << { kind: :hidden, key: :copy, value: true }
		res.last << { kind: :hidden, key: :duration, value: @event.duration }
		res.last << { kind: :hidden, key: :id, value: @event.id }
		res.last << { kind: :hidden, key: :rdx, value: @rdx } if @rdx
		res
	end

	# return adequate notice depending on @event kind
	def event_create_notice
		case @event.kind.to_sym
		when :rest
			msg = I18n.t("rest.created") + "#{@event.to_s(style: "notice")}"
		when :train
			msg = I18n.t("train.created") + "#{@event.date_string}"
		when :match
			msg = I18n.t("match.created") + "#{@event.to_s(style: "notice")}"
		end
		flash_message(msg, "success")
	end

	# return adequate notice depending on @event kind
	def event_delete_notice
		case @event.kind.to_sym
		when :rest
			msg = I18n.t("rest.deleted") + "#{@event.to_s(style: "notice")}"
		when :train
			msg = I18n.t("train.deleted") + "#{@event.date_string}"
		when :match
			msg = I18n.t("match.deleted") + "#{@event.to_s(style: "notice")}"
		end
		flash_message(msg)
	end

	# fields to display player's edit stats form for an event
	def event_edit_player_stats
		@sport.player_training_stats_form(@event, player_id: @player.id)
	end


	def event_form_data_options(event, title)
		if event.match?
			{ controller: "match-location", title:, turbo_frame: "_top" }
		else
			{ controller: "mandatory-fields", title:, turbo_frame: "_top" }
		end
	end

	# return icon and top of fields definition
	def event_index_title(team: nil, season: nil)
		title    = (team ? team.nick : (season ? season.name : I18n.t("calendar.label")))
		subtitle = (team ? team.category.name : I18n.t("scope.all"))
		res      = title_start(icon: symbol_hash("calendar"), title:, subtitle:)
		res     += [ [ gap_field(size: 1), string_field(team.division.name + " (#{team.season.name})") ] ] if team
		res
	end

	# A Field Component with top link + table for events. obj is the parent oject (season/team)
	# if it's a season, we need to reference everything to the userclub
	def event_list_table(obj:)
		if clubevent = (obj.class==Season)	# global club event ?
			season_id = obj.id
			events    = @club.upcoming_events
		else
			clubevent = true unless (team_id = obj&.id)
			events    = obj&.events&.short_term
		end
		title = [
			{ kind: :normal, value: I18n.t("calendar.date"), align: "center" },
			{ kind: :normal, value: I18n.t("calendar.time"), align: "center" },
			{ kind: :normal, value: I18n.t("event.single"), cols: 4 }
		]
		rows    = event_rows(events:, season_id:)
		btn_add = new_event_button(obj:, clubevent:)
		title << btn_add if btn_add
		[ event_list_toprow(clubevent:), [ { kind: :table, value: { title:, rows: }, cols: 3 } ] ]
	end

	# fields to display player's stats for an event
	def event_player_stats
		@sport.player_training_stats_show(@event, player_id: @player.id)
	end

	# return icon and top of fields definition for Tasks
	def event_task_title(subtitle:)
		event_title(subtitle:, chart: true)
	end

	# return icon and top of fields definition
	def event_title(subtitle: nil, form: nil, cols: nil, chart: nil, teams: nil)
		if teams	# we are going to prepare a copy of the event
			t_id = @event.team ? @event.team.id : teams.first.id
			copy = true
			res  = title_start(icon: @event.symbol, title: @event.title(copy: true), rows: @event.rest? ? 3 : nil, cols:)
			res << [ { kind: :select_collection, key: :team_id, options: teams, value: t_id, cols: cols } ]
		else
			res = title_start(icon: @event.symbol, title: @event.title(show: true), rows: @event.rest? ? 3 : nil, cols:)
			res.last << gap_field
			case @event.kind.to_sym
			when :rest then rest_title(res:, cols:, form:)
			when :match then match_title(res:, cols:, form:)
			when :train then train_title(res:, cols:, form:, subtitle:, chart:)
			end
		end
		event_top_right(res:, form:, copy:)
		res
	end

	# return adequate notice depending on @event kind
	def event_update_notice(msg, changed: false)
		if changed
			if @event.train?
				msg += @event.date_string
			elsif msg != I18n.t("stat.updated")
				msg += @event.to_s(style: "notice")
			end
			flash_message(msg, "success")
		else
			flash_message(I18n.t("status.no_data"), "info")
		end
	end

	# profile of event workload (task types)
	# returns a hash with time used split by kinds & skills
	def event_workload(name:)
		title = I18n.t("train.workload_by") + " " + I18n.t("#{name}.single")
		data  = {}
		@event.tasks.each { |task| # kind
			case name
			when "kind"
				k_name = task.drill.kind.name
				data[k_name] = data[k_name] ? data[k_name] + task.duration : task.duration
			when "skill"
				task.drill.skills.each { |skill|
					s_name = skill.concept
					data[s_name] = data[s_name] ? data[s_name] + task.duration : task.duration
				}
			end
		}
		{ title: title, data: data }
	end

	# FieldComponents to show a match
	def match_show
		match_fields(edit: false)
	end

	# return fields definition for match form
	def match_form(new: false)
		match_fields(edit: true, new:)
	end

	# player table for a match
	def match_roster_table(edit: false)
		a_rules = @sport.rules.key(@event.team.category.rules)
		if (outings = @sport.match_outings(a_rules))
			table = @sport.outings_table(@event, outings, edit:, rdx: @rdx)
			stim = "outings"
		else
			table = @sport.stats_table(@event, edit:, rdx: @rdx)
			stim = nil
		end
		{ data: table, controller: stim }
	end

	# return accordion for event tasks
	def task_accordion
		tasks   = Array.new
		@event.tasks.each { |task|
			item = {}
			item[:url]     = show_task_event_path(task_id: task.id, rdx: @rdx)
			item[:turbo]   = "modal"
			item[:head]    = task.headstring
			item[:content] = FieldsComponent.new(task_show(task:, team: @event.team, title: nil))
			tasks << item
		}
		tasks
	end

	# fields to show in task views
	def task_show(task:, team:, title: true)
		res = []
		res << [
			symbol_field("drill", { namespace: task&.drill&.sport&.name || "sport", size: "30x30" }, align: "center"),
			{ kind: :label, value: task.drill.name },
			gap_field,
			{ kind: :icon_label, symbol: "clock", label: task.s_dur }
		] if title

		if task.drill.steps.empty?
			res << [ { kind: :text, value: task.drill.description } ]
		else
			res << [ { kind: :steps, steps: task.drill.steps, court: task.drill.court_mode } ]
		end
		if task.remarks?
			res << [ { kind: :label, value: I18n.t("task.remarks") } ]
			res << [ { kind: :action_text, value: task.remarks.body.to_s, size: 28 } ]
		end
		res
	end

	# data fields for task edit/add views
	def task_form(search_in:)
		res  = [ event_form_hidden_fields(@event.team_id) ]
		res += [
			[
				topcell_field(I18n.t("task.number")),
				topcell_field(I18n.t("drill.single")),
				topcell_field(I18n.t("task.duration"))
			],
			[
				{ kind: :side_cell, value: @task.order },
				{ kind: :select_load, key: :drill_id, url: search_in, options: @drills, value: @drill&.id },
				{ kind: :number_box, key: :duration, min: 1, max: 90, size: 3, value: @task.duration }
			],
			[
				{ kind: :hidden, key: :task_id, value: @task.id },
				{ kind: :hidden, key: :order, value: @task.order }
			]
		]
	end

	# fields for task edit/add views
	def task_form_description
		if @task.drill
			[ [ { kind: :string, value: @task.drill.explanation.empty? ? @task.drill.description : @task.drill.explanation } ] ]
		else
			nil
		end
	end

	# fields to edit task remarks
	def task_form_remarks
		[
			[ { kind: :label, value: I18n.t("task.remarks") } ],
			[ { kind: :rich_text_area, key: :remarks, value: @task.remarks, size: 28 } ]
		]
	end

	# return definition @fields for show_training
	def training_show
		[ [ { kind: :accordion, title: I18n.t("task.many"),	tail: "#{I18n.t("stat.total")}: #{@event.work_duration}", objects: task_accordion } ] ]
	end

	# fields for training sesssion targets
	def training_target
		res = [
			[
				{ kind: :side_cell, value: I18n.t("target.abbr"), rows: 2 },
				topcell_field(I18n.t("target.focus.def_a")),
				{ kind: :lines, value: @event.def_targets, cols: 5 }
			],
			[
				topcell_field(I18n.t("target.focus.att_a")),
				{ kind: :lines, value: @event.off_targets, cols: 5 }
			]
		]
		res << gap_row(cols: 3)
	end

	private
		# return a button field to copy event - if possible
		def event_copy_button
			if u_coach? or u_manager?
				{ kind: :action, symbol: symbol_hash("copy", type: :button), label: I18n.t("action.copy"), url: copy_event_path(@event, cal: @cal, rdx: @rdx), frame: "modal" }
			end
		end

		# define the toprow for an events list (just above the table itself)
		def event_list_toprow(clubevent:)
			calendurl = clubevent ? club_events_path(@clubid, season_id: @season&.id, rdx: @rdx) : team_events_path(@team, rdx: @rdx)
			toprow = [	#  top row above the table
				button_field(
					{ kind: :link, symbol: "calendar", label: I18n.t("calendar.label"), size: "30x30", url: calendurl },
					class: "align-middle text-indigo-900"
				)
			]
			toprow += [	# team events--> add a team_attendance button
				gap_field,
				button_field(
					{ kind: :link, symbol: "attendance", label: I18n.t("calendar.attendance"), flip: true, size: "30x30", url: attendance_team_path(@team, rdx: @rdx), align: "right", frame: "modal" },
					class: "align-middle text-indigo-900"
				)
			] unless clubevent
			toprow
		end

		# return TableComponent @rows for events passed
		def event_rows(events:, season_id:)
			rows  = Array.new
			events&.each do |event|
				unless season_id && event.rest? && event.team_id>0 # show only general holidays in season events view
					row = { url: event_path(event, season_id:, rdx: @rdx), frame: (event.rest? ? "modal": "_top"), items: [] }
					row[:items] << { kind: :normal, value: event.date_string, align: "center" }
					row[:items] << { kind: :normal, value: event.time_string(false), align: "center" }
					event.to_hash.each_value do |row_f|
						n_row = event.match? ? { kind: :normal, value: row_f.to_s, cols: 1 } : { kind: :normal, value: event.to_s, cols: 4 }
						row[:items] << n_row
					end
					row[:items] << button_field({ kind: :delete, url: row[:url], name: event.to_s }) if u_manager? or (event.team_id>0 and event.team.has_coach(u_coachid))
					rows << row
				end
			end
			rows
		end

		# complete event title with top-right corner elements
		def event_top_right(res:, form: nil, copy: false)
			if form # top right corner of title
				res[0] << symbol_field("calendar")
				res[0] << { kind: :date_box, key: :start_date, s_year: @event.team_id > 0 ? @event.team.season.start_date : @event.start_date, e_year: @event.team_id > 0 ? @event.team.season.end_year : nil, value: @event.start_date }
				unless @event.rest? # add start_time inputs
					res[1] << symbol_field("clock")
					res[1] << { kind: :time_box, key: :hour, hour: @event.hour, mins: @event.min, mandatory: true }
				end
				h_fields = event_form_hidden_fields(copy ? @event.team_id : nil)
				h_fields << { kind: :hidden, key: :kind, value: @event.kind }
				res << h_fields
			else
				res[0] << symbol_field("calendar", { title: I18n.t("calendar.date") })
				res[0] << { kind: :string, value: @event.date_string }
				unless @event.rest?
					res[1] << symbol_field("clock", { title: I18n.t("calendar.time") })
					res[1] << { kind: :string, value: @event.time_string }
				end
			end
		end

		def event_form_hidden_fields(teamid)
			res = []
			res << { kind: :hidden, key: :team_id, value: teamid } if teamid
			res << { kind: :hidden, key: :cal, value: @cal } if @cal
			res << { kind: :hidden, key: :rdx, value: @rdx } if @rdx
			res << { kind: :hidden, key: :kind, value: @event.kind } if @event
			res
		end

		# serves for both match_show and match_edit
		def match_fields(edit:, new: false)
			if edit
				@sport.match_form(@event, new:)
			else
				@sport.match_show(@event)
			end
		end

		# complete event title for matches
		def match_title(res:, cols:, form:)
			res << [ { kind: :subtitle, value: @event.team.category.name }, gap_field ]
			res << [ gap_field(size: 1),	string_field(@event.team.division.name + " (#{@event.team.season.name})"), gap_field ]
			if form
				res[0][1][:cols] = nil
				res << [
					gap_field(size: 1),
					{ kind: :side_cell, value: I18n.t("match.single"), align: "left", cols: 2 }
				]
				res << [
					symbol_field("location"),
					{ kind: :select_collection, key: :location_id, options: Location.home, value: @event.location_id, s_target: "data-match-location-target='locationId'", cols: 6 },
					{ kind: :hidden, key: :homecourt_id, value: @event.team.homecourt_id, h_data: { match_location_target: "homeCourtId" } }
				]
			else
				if @event.location.gmaps_url
					res.last << button_field({ kind: :location, symbol: "gmaps", url: @event.location.gmaps_url, label: @event.location.name }, cols: 2)
				end
				if u_manager? || @event.team.has_coach(u_coachid)
					res << [
						gap_field(size: 1),
						{ kind: :side_cell, value: I18n.t("match.single"), align: "left", cols: 2 },
						button_field(
							{ kind: :link, symbol: "attendance", label: I18n.t("match.roster"), url: attendance_event_path(rdx: @rdx, cal: @cal), frame: "modal" },
							align: "left",
							cols: 2
						)
					]
					res << gap_row
				end
			end
		end

		# complete event_title for train events
		def train_title(res:, cols:, form:, subtitle: nil, chart: nil, rdx: @rdx)
			res << [ { kind: :subtitle, value: @event.team.category.name, cols: } ]
			unless chart
				if form
					res.last << gap_field
					res << [ gap_field(size: 1), string_field(@event.team.division.name + " (#{@event.team.season.name})", cols: 2) ]
					res.last << workload_button(align: "left", cols: 2, rows: 2) if @event.id
					res << [ gap_field(size: 1), { kind: :side_cell, value: I18n.t("train.single"), cols: 2, align: "left" } ]
					res << gap_row(cols: 8)
				elsif (u_manager? || u_coach?) && @event.id
					res.first[1][:cols] = 4	# modify cols to avoid issues with show
					res.last << pdf_button(event_path(@event, format: :pdf))
					res.last << gap_field
					res << [
						button_field(event_copy_button, align: "left", class: "align-top", rows: 2),
						string_field(@event.team.division.name + " (#{@event.team.season.name})", cols: 5, align: "left"),
						workload_button(align: "left", cols: 2, rows: 2)
					]
					res << [ { kind: :side_cell, value: I18n.t("train.single"), align: "left", cols: 5, class: "align-top" } ]
					res << [
						gap_field(size: 1, cols: 6),
						button_field(
							{ kind: :link, symbol: "attendance", label: I18n.t("calendar.attendance"), url: attendance_event_path(rdx: @rdx, cal: @cal), frame: "modal" },
							align: "left",
							cols: 2
						)
					]
				elsif u_player?
					res << [ gap_field, { kind: :label, value: current_user.to_s, cols: 3 } ]
				end
			end
		end

		# complete event_title for rest events
		def rest_title(team: nil, season: nil, res:, cols:, form:)
			res << [ { kind: :subtitle, value: team&.nick || season&.name || "", cols: cols } ] if team or season
			res << [ form ? { kind: :text_box, key: :name, value: @event.name, placeholder: I18n.t("person.name") } : { kind: :label, value: @event.name } ]
		end

		# return the dropdown element to access workload charts
		def workload_button(cols: 2, rows: 1, align: "center")
			{ kind: :dropdown, align:, cols:, rows:,
				button: { kind: :link, symbol: "pie", label: I18n.t("train.workload"), name: "show-chart",
					options: [
						{ label: I18n.t("kind.single"), url: load_chart_event_path(name: "kind"), data: { turbo_frame: :modal } },
						# {label: I18n.t("target.many"), url: load_chart_event_path(name: "target"), data: {turbo_frame: :modal}},
						{ label: I18n.t("skill.single"), url: load_chart_event_path(name: "skill"), data: { turbo_frame: :modal } }
					]
				}
			}
		end

		# dropdown button definition to create a new Event
		def new_event_button(obj:, clubevent: nil)
			if clubevent	# paste season event button
				button_field({ kind: :add, url: new_event_path(event: { kind: :rest, club_id: @clubid, team_id: 0, season_id: obj&.id }, rdx: @rdx), frame: "modal" }) if u_manager? && obj==Season.latest
			elsif obj.class == Team && team_manager?(obj) # new team event
				button = { kind: :add, name: "add-event", options: [] }
				button[:options] << { label: I18n.t("train.single"), url: new_event_path(event: { kind: :train, team_id: obj.id }, rdx: @rdx), data: { turbo_frame: :modal } }
				button[:options] << { label: I18n.t("match.single"), url: new_event_path(event: { kind: :match, team_id: obj.id }, rdx: @rdx), data: { turbo_frame: :modal } }
				button[:options] << { label: I18n.t("rest.single"), url: new_event_path(event: { kind: :rest, team_id: obj.id }, rdx: @rdx), data: { turbo_frame: :modal } }
				{ kind: :dropdown, button:, class: "bg-white" }
			else
				nil
			end
		end
end
