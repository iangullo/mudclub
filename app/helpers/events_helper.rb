# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2023  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
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
	# return icon and top of FieldsComponent
	def event_index_title(team: nil, season: nil)
		title    = team ? (team.name + " (#{team.season.name})") : season ? season.name : I18n.t("calendar.label")
		subtitle = (title == I18n.t("calendar.label")) ? I18n.t("scope.all") : I18n.t("calendar.label")
		res      = title_start(icon: "calendar.svg", title: title)
		res << [{kind: "subtitle", value: subtitle}]
	end

	# return icon and top of FieldsComponent
	def event_title_fields(subtitle: nil, form: nil, cols: nil, chart: nil)
		res = title_start(icon: @event.pic, title: @event.title(show: true), rows: @event.rest? ? 3 : nil, cols:)
		res.last << {kind: "gap"}
		case @event.kind.to_sym
		when :rest then rest_title(res:, cols:, form:)
		when :match then match_title(res:, cols:, form:)
		when :train then train_title(res:, cols:, form:, subtitle:, chart:)
		end
		event_top_right_fields(res:, form:)
		#res << [{kind: "top-cell", value: "A"}, {kind: "top-cell", value: "B"}, {kind: "top-cell", value: "C"}, {kind: "top-cell", value: "D"}, {kind: "top-cell", value: "E"}, {kind: "top-cell", value: "F"}]
		res << [{kind: "gap", size:1, cols: 6, class: "text-xs"}] unless @event.match? and form==nil
		res
	end

	# FieldComponents for event attendance
	def event_attendance_title
		res = title_start(icon: "attendance.svg", title: @event.team.name)
		res[0] << {kind: "gap"}
		res << [
			{kind: "subtitle", value: @event.to_s},
			{kind: "gap"}
		]
		event_top_right_fields(res:)
		res << [{kind: "gap", size:1, cols: 6, class: "text-xs"}]
	end

	# return icon and top of FieldsComponent for Tasks
	def event_task_title(subtitle:)
		res = event_title_fields(subtitle:, cols: 3)
	end

	# A Field Component with top link + grid for events. obj is the parent oject (season/team)
	def event_list_grid(events:, obj:, retlnk:)
		for_season = (obj.class==Season)
		title  = [
			{kind: "normal", value: I18n.t("calendar.date"), align: "center"},
			{kind: "normal", value: I18n.t("calendar.time"), align: "center"},
			{kind: "normal", value: I18n.t("event.single"), cols: 4}
		]
		rows    = event_rows(events:, season_id: for_season ? obj.id : nil, retlnk: retlnk)
		btn_add = new_event_button(obj:, for_season:)
		title << btn_add if btn_add
		if for_season
			fields = [[
				button_field(
					{kind: "link", icon: "calendar.svg", label: I18n.t("calendar.label"), size: "30x30", url: events_path(season_id: @season.id)},
					cols: 4,
					class: "align-middle text-indigo-900"
				)
			]]
		else
			fields = [[
				button_field(
					{kind: "link", icon: "calendar.svg", label: I18n.t("calendar.label"), size: "30x30", url: events_path(team_id: obj.id)},
					class: "align-middle text-indigo-900"
				),
				{kind: "gap"},
				button_field(
					{kind: "link", icon: "attendance.svg", label: I18n.t("calendar.attendance"), flip: true, size: "30x30", url: attendance_team_path(obj), align: "right", frame: "modal"},
					class: "align-middle text-indigo-900"
				)
			]]
		end
		fields << [{kind: "grid", value: {title: title, rows: rows}, cols: 3}]
		return fields
	end

	# FieldComponents to show an attendance form
	def event_attendance_form_fields
		res = [[
			{kind: "gap", size: 2},
			{kind: "side-cell", value: I18n.t(@event.match? ? "match.roster" : "calendar.attendance"), align: "left"}
		]]
		res << [
			{kind: "gap", size: 2},
			{kind: "select-checkboxes", key: :player_ids, options: @event.team.players.active}
		]
	end

	#FieldComponents to show a match
	def match_show_fields(sport)
		res = match_fields(sport, edit: false)
		res << [{kind: "grid", value: match_roster_grid(sport), cols: res.last.last[:cols]}]
	end

	# return FieldsComponent for match form
	def match_form_fields(sport, new: false)
		res = match_fields(sport, edit: true, new:)
		res << [{kind: "grid", value: match_roster_grid(sport, edit: true), cols: res.last.last[:cols]}] unless new
		res
	end

	# fields to display player's stats for an event
	def event_player_shots_fields
		@sport.player_training_stats_fields(event_id: @event.id, player_id: @player.id)
	end

	# fields to display player's edit stats form for an event
	def event_edit_player_shots_fields
		@sport.player_training_stats_form_fields(event_id: @event.id, player_id: @player.id)
	end

	# return FieldsComponent @fields for show_training
	def training_show_fields
		res = [[{kind: "accordion", title: I18n.t("task.many"), tail: "#{I18n.t("stat.total")}:" + " " + @event.work_duration, objects: task_accordion}]]
	end

	# fields to show in task views
	def task_show_fields(task:, team:, title: true)
		res = []
		res << [
			{kind: "icon", value: "drill.svg", size: "30x30", align: "center"},
			{kind: "label", value: task.drill.name},
			{kind: "gap"},
			{kind: "icon-label", icon: "clock.svg", label: task.s_dur}
		] if title
		res << [{kind: "cell", value: task.drill.explanation.empty? ? task.drill.description : task.drill.explanation}]
		if task.remarks?
			res << [{kind: "label", value: I18n.t("task.remarks")}]
			res << [{kind: "cell", value: task.remarks, size: 28}]
		end
		res
	end

	# data fields for task edit/add views
	def task_form_fields(search_in:, retlnk:)
		[
			[
				{kind: "top-cell", value: I18n.t("task.number")},
				{kind: "top-cell", value: I18n.t("drill.single")},
				{kind: "top-cell", value: I18n.t("task.duration")}
			],
			[
				{kind: "side-cell", value: @task.order},
				{kind: "select-load", key: :drill_id, url: search_in, options: @drills, value: @drill ? @drill.id : nil, hidden: @task.id},
				{kind: "number-box", key: :duration, min: 1, max: 90, size: 3, value: @task.duration}
			],
			[
				{kind: "hidden", key: :task_id, value: @task.id},
				{kind: "hidden", key: :order, value: @task.order},
				{kind: "hidden", key: :retlnk, value: retlnk}
			]
		]
	end

	# fields for task edit/add views
	def task_form_description
		if @task.drill
			[[{kind: "string", value: @task.drill.explanation.empty? ? @task.drill.description : @task.drill.explanation}]]
		else
			nil
		end
	end

	# fields to edit task remarks
	def task_form_remarks
		[
			[{kind: "label", value: I18n.t("task.remarks")}],
			[{kind: "rich-text-area", key: :remarks, value: @task.remarks, size: 28}],
		]
	end

	# return accordion for event tasks
	def task_accordion
		tasks   = Array.new
		@event.tasks.each { |task|
			item = {}
			item[:url]     = show_task_event_path(task_id: task.id)
			item[:turbo]   = "modal"
			item[:head]    = task.headstring
			item[:content] = FieldsComponent.new(fields: task_show_fields(task:, team: @event.team, title: nil))
			tasks << item
		}
		tasks
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
				task.drill.skills.each {|skill|
					s_name = skill.concept
					data[s_name] = data[s_name] ? data[s_name] + task.duration : task.duration
				}
			end
		}
		{title: title, data: data}
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
	def event_update_notice(attendance: nil)
		case @event.kind.to_sym
		when :rest
			msg = I18n.t("rest.updated") + "#{@event.to_s(style: "notice")}"
		when :train
			msg = I18n.t(attendance ? "train.att_check" : "train.updated") + "#{@event.date_string}"
		when :match
			msg = I18n.t(attendance ? "match.att_check" : "match.updated") + "#{@event.to_s(style: "notice")}"
		end
		if attendance or @event.modified?
			return flash_message(msg, "success")
		else
			return flash_message(I18n.t("status.no_data"), "info")
		end
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

	private
		# complete event_title for rest events
		def rest_title(team: nil, season: nil, res:, cols:, form:)
			res << [{kind: "subtitle", value: team ? team.name : season ? season.name : "", cols: cols}] if team or season
			res << [form ? {kind: "text-box", key: :name, value: @event.name, placeholder: I18n.t("person.name")} : {kind: "label", value: @event.name}]
		end

		# complete event title for matches
		def match_title(res:, cols:, form:)
			if form
				res << [
					{kind: "icon", value: "location.svg"},
					{kind: "select-collection", key: :location_id, options: Location.home, value: @event.location_id},
					{kind: "gap"}
				]
				res << [
					{kind: "gap", size: 1, cols: 4},
					{kind: "icon", value: "attendance.svg"},
					button_field({kind: "link", label: I18n.t("match.roster"), url: attendance_event_path, frame: "modal"}, align: "left")
				] if @event.id
			else
				if @event.location.gmaps_url
					res << [
						button_field({kind: "location", icon: "gmaps.svg", url: @event.location.gmaps_url, label: @event.location.name}),
						{kind: "gap"}
					]
				else
					res << [{kind: "gap", cols: 2}]
				end
				res << [
					{kind: "gap", size: 1, cols: 3},
					button_field(
						{kind: "link", icon: "attendance.svg", label: I18n.t("match.roster"), url: attendance_event_path, frame: "modal"},
						align: "left",
						cols: 2
					)
				]
			end
		end

		# serves for both match_show and match_edit
		def match_fields(sport, edit:, new: false)
			edit ? sport.match_form_fields(@event, new:) : sport.match_show_fields(@event)
		end

		# player grid for a match
		def match_roster_grid(sport, edit: false)
			a_rules = sport.rules.key(@event.team.category.rules)
			if (outings = sport.match_outings(a_rules))
				grid = sport.outings_grid(@event, outings, edit:)
			else
				grid = sport.stats_grid(@event, edit:)
			end
			grid
		end

		# complete event_title for train events
		def train_title(res:, cols:, form:, subtitle: nil, chart: nil)
			value = subtitle || I18n.t("train.single")
			res << [{kind: "subtitle", value:, cols:}, {kind: "gap"}]
			unless chart
				if form
					res << [workload_button(align: "left", cols: 3)] if @event.id
				elsif (u_manager? || u_coach?)
					res << [
						workload_button(align: "left", cols: 4),
						{kind: "gap", size: 1},
						button_field(
							{kind: "link", icon: "attendance.svg", label: I18n.t("calendar.attendance"), url: attendance_event_path, frame: "modal"},
							align: "left",
							cols: 2
						)
					]
					res << [{kind: "gap", size:1, cols: 6, class: "text-xs"}]
					res << [
						{kind: "side-cell", value: I18n.t("target.abbr"),rows: 2},
						{kind: "top-cell", value: I18n.t("target.focus.def_a")},
						{kind: "lines", value: @event.def_targets, cols: 5}
					]
					res << [
						{kind: "top-cell", value: I18n.t("target.focus.ofe_a")},
						{kind: "lines", value: @event.off_targets, cols: 5}
					]
				elsif u_player?
					res << [{kind: "gap"}, {kind: "label", value: current_user.to_s, cols: 3}]
				end
			end
		end

		# complete event title with top-right corner elements
		def event_top_right_fields(res:, form: nil)
			if form # top right corner of title
				res[0] << {kind: "icon", value: "calendar.svg"}
				res[0] << {kind: "date-box", key: :start_date, s_year: @event.team_id > 0 ? @event.team.season.start_date : @event.start_date, e_year: @event.team_id > 0 ? @event.team.season.end_year : nil, value: @event.start_date}
				unless @event.rest? # add start_time inputs
					res[1] << {kind: "icon", value: "clock.svg"}
					res[1] << {kind: "time-box", key: :hour, hour: @event.hour, mins: @event.min}
				end
				res.last << {kind: "hidden", key: :season_id, value: @season.id} if @event.team.id==0
				res.last << {kind: "hidden", key: :team_id, value: @event.team_id}
				res.last << {kind: "hidden", key: :kind, value: @event.kind}
			else
				res[0] << {kind: "icon-label", icon: "calendar.svg", label: @event.date_string}
				res[1] << {kind: "icon-label", icon: "clock.svg", label: @event.time_string} unless @event.rest?
			end
		end

		# return GridComponent @rows for events passed
		def event_rows(events:, season_id:, retlnk:)
			rows  = Array.new
			events.each { |event|
				unless season_id and event.rest? and event.team_id>0 # show only general holidays in season events view
					row = {url: event_path(event, season_id:, retlnk:), frame:(event.rest? ? "modal": "_top"), items: []}
					row[:items] << {kind: "normal", value: event.date_string, align: "center"}
					row[:items] << {kind: "normal", value: event.time_string(false), align: "center"}
					event.to_hash.each_value { |row_f|
						n_row = event.match? ? {kind: "normal", value: row_f.to_s, cols: 1} : {kind: "normal", value: event.to_s, cols: 4}
						row[:items] << n_row
					}
					row[:items] << button_field({kind: "delete", url: row[:url], name: event.to_s}) if u_manager? or (event.team_id>0 and event.team.has_coach(u_coachid))
					rows << row
				end
			}
			rows
		end

		# return the dropdown element to access workload charts
		def workload_button(cols: 2, align: "center")
			res = { kind: "dropdown", align:, cols:,
				button: {kind: "link", icon: "pie.svg", label: I18n.t("train.workload"), name: "show-chart",
					options: [
						{label: I18n.t("kind.single"), url: load_chart_event_path(name: "kind"), data: {turbo_frame: :modal}},
						#{label: I18n.t("target.many"), url: load_chart_event_path(name: "target"), data: {turbo_frame: :modal}},
						{label: I18n.t("skill.single"), url: load_chart_event_path(name: "skill"), data: {turbo_frame: :modal}}
					]
				}
			}
		end

		# dropdown button definition to create a new Event
		def new_event_button(obj:, for_season: nil)
			if for_season	# paste season event button
				return button_field({kind: "add", url: new_event_path(event: {kind: :rest, team_id: 0, season_id: obj.id}), frame: "modal"}) if u_manager? && obj==Season.latest
			elsif obj.class == Team && obj.has_coach(u_coachid) # new team event
				button = {kind: "add", name: "add-event", options: []}
				button[:options] << {label: I18n.t("train.single"), url: new_event_path(event: {kind: :train, team_id: obj.id}), data: {turbo_frame: :modal}}
				button[:options] << {label: I18n.t("match.single"), url: new_event_path(event: {kind: :match, team_id: obj.id}), data: {turbo_frame: :modal}}
				button[:options] << {label: I18n.t("rest.single"), url: new_event_path(event: {kind: :rest, team_id: obj.id}), data: {turbo_frame: :modal}}
				return {kind: "dropdown", button: button, class: "bg-white"}
			else
				return nil
			end
		end
end
