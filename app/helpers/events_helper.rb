# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
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
	# self explanatory
	def event_action_path(action, event: @event, cal: @cal, **opts)
		path_for(event, action:, cal:, **opts)
	end

	# fields to display athlete's stats for an event
	def event_athlete_stats
		@sport.athlete_training_stats_show(@event, athlete_id: @athlete.id)
	end

	# FieldComponents for event attendance
	def event_attendance_header
		res = title_start(icon: symbol_hash(:attendance), title: @team.nick, subtitle: @team.category.name)
		res[0] << gap_item
		res[1] << gap_item
		event_top_right(res:)
		res << [ gap_item(0), string_item(@team.division.name + " (#{@team.season.name})", cols: 5, align: :left) ]
		res << gap_row(cols: 6)
	end

	# FieldComponents to show an attendance form
	def event_attendance_form
		res = [ [
			gap_item(2),
			{ kind: :side_cell, value: @event.kind_match? ? @event.term(:match, :roster) : Attendance.label, align: :left }
		] ]
		res << [
			gap_item(2),
			{ kind: :select_checkboxes, key: :athlete_assignment_ids, options: @team.athletes.active.by_number }
		]
		res << [ hidden_input(:rdx, @rdx) ] if @rdx
		res << [ hidden_input(:team_id, @teamid) ] if @teamid
		res
	end

	# return a fields to show a copy event form
	def event_copy
		res = event_header(form: true, teams: @teams)
		res.last << hidden_input(:copy, true)
		res.last << hidden_input(:duration, @event.duration)
		res.last << hidden_input(:id, @event.id)
		res.last << hidden_input(:rdx, @rdx) if @rdx
		res
	end

	# return adequate notice depending on @event kind
	def event_create_notice
		flash_message(@event.specific.created_notice, "success")
	end

	# return adequate notice depending on @event kind
	def event_delete_notice
		flash_message(@event.specific.deleted_notice)
	end

	# fields to display athlete's edit stats form for an event
	def event_edit_athlete_stats
		@sport.athlete_training_stats_form(@event, athlete_id: @athlete.id)
	end

	def event_form_data_options(event, title)
		if event.kind_match?
			{ controller: "match-location", title:, turbo_frame: "_top" }
		else
			{ controller: "mandatory-fields", title:, turbo_frame: "_top" }
		end
	end

	def event_form_hidden_inputs(teamid)
		res = []
		res << hidden_input(:team_id, teamid)   if teamid
		res << hidden_input(:cal, @cal)         if @cal
		res << hidden_input(:rdx, @rdx)         if @rdx
		res << hidden_input(:kind, @event.kind) if @event
		res
	end

	# return icon and top of fields definition
	def event_header(subtitle: nil, form: nil, cols: nil, chart: nil, teams: nil)
		if teams
			t_id = @team ? @team.id : teams.first.id
			copy = true
			res  = title_start(icon: @event.symbol, title: @event.title(copy: true),
												rows: @event.specific.title_rows, cols:)
			res << [ { kind: :select_collection, key: :team_id, options: teams, value: t_id, cols: cols } ]
		else
			res = title_start(icon: @event.symbol, title: @event.title(show: true),
												rows: @event.specific.title_rows, cols:)
			res.last << gap_item
			@event.specific.header_fragments(
				self, res:,
				policy: @policy, user: current_user,
				cols:, form:, subtitle:, chart:
			)
		end
		event_top_right(res:, form:, copy:)
		res
	end

	# return icon and top of fields definition
	def event_index_title(team: nil, season: nil)
		title    = (team ? team.nick : (season ? season.name : Calendar.label))
		subtitle = (team ? team.category.name : Category.val(:all))
		res      = title_start(icon: symbol_hash(:calendar), title:, subtitle:)
		res     += [ [ gap_item(1), string_item(team.division.name + " (#{team.season.name})") ] ] if team
		res
	end

	# A Field Component with top link + table for events. obj is the parent oject (season/team)
	# if it's a season, we need to reference everything to the userclub
	def event_list_table(obj)
		case obj
		when Club
			season_id = Season.latest.id
			events    = @club.upcoming_events
		when Team
			events    = obj&.events&.short_term
		else
			return []
		end

		title = [
			{ kind: :normal, value: Calendar.fld(:date), align: :center },
			{ kind: :normal, value: Calendar.fld(:time), align: :center },
			{ kind: :normal, value: Event.label, cols: 4 }
		]
		rows    = event_rows(events:, season_id:)
		[ event_list_toprow(obj), [ table_item(title:, rows:, cols: 4) ] ]
	end

	# return pdf page header for exports based on event title
	def event_pdf_header
		club = @event&.team&.club || @event.club
		return title unless club

		row1 = [
			{ kind: :header_icon, value: club.logo, rows: 2 }, # col 0
			label_item(club.nick),                          # col 1
			label_item(@event.kind_label, align: :center),  # col 2
			symbol_item(:calendar),                         # col 3
			label_item(@event.date_string, align: :right)   # col 4
		]

		# col 0 is already occupied by club.logo (rowspan: 2)
		if @event.team
			row2 = [
				label_item(@event.team.name, align: :left), # col 1
				gap_item                                    # col 2
			]
		else
			row2 = [ gap_item(cols: 2) ]                  # cols 1, 2
		end

		row2 += [
			symbol_item(:clock),                          # col 3
			label_item(@event.time_string, align: :right) # col 4
		]

		[ row1, row2 ]
	end

	# return adequate notice depending on @event kind
	def event_update_notice(msg, changed: false)
		flash_message(@event.specific.updated_notice(msg, changed:), changed ? "success" : "info")
	end

	private

		# define the toprow for an events list (just above the table itself)
		def event_list_toprow(obj)
			clubevent = obj.is_a?(Club)
			calendurl = clubevent ? club_events_path(obj, season_id: @season&.id) : club_team_events_path(obj.club, obj)
			toprow = [	#  top row above the table
				normal_button(
					{ kind: :link, symbol: :calendar, label: Calendar.label, size: "30x30", url: calendurl },
					class: "align-middle text-indigo-900"
				)
			]
			btn_add = new_event_button(obj)
			toprow << btn_add if btn_add

			toprow += [	# team events--> add a team_attendance button
				gap_item(8),
				normal_button(
					{ kind: :link, symbol: :attendance, label: Attendance.label, flip: true, size: "30x30", url: path_for(obj, action: :attendance), align: :right, frame: :modal },
					class: "align-middle text-indigo-900"
				)
			] unless clubevent
			toprow
		end

		# return TableComponent @rows for events passed
		def event_rows(events:, season_id:)
			rows  = Array.new
			events&.each do |event|
				unless season_id && event.kind_holiday? && event.team_id.to_i > 0 # show only general holidays in season events view
					url = path_for(event, cal: @cal)
					row = { url:, frame: (event.kind_holiday? ? "modal": "_top"), items: [] }
					row[:items] << { kind: :normal, value: event.date_string, align: :center }
					row[:items] << { kind: :normal, value: event.time_string(false), align: :center }
					event.to_hash.each_value do |row_f|
						n_row = event.kind_match? ? { kind: :normal, value: row_f.to_s, cols: 1 } : { kind: :normal, value: event.to_s, cols: 4 }
						row[:items] << n_row
					end
					row[:items] << normal_button({ kind: :delete, url: row[:url], name: event.to_s }) if @policy.destroy?
					rows << row
				end
			end
			rows
		end

		# complete event title with top-right corner elements
		def event_top_right(res:, form: nil, copy: false)
			if form # top right corner of title
				clubevent = @event.team_id.to_i > 0
				res[0] << symbol_item(:calendar)
				res[0] << { kind: :date_box, key: :start_date, s_year: clubevent ? @team.season.start_date : @event.start_date, e_year: clubevent ? @team.season.end_year : nil, value: @event.start_date }
				if @event.specific.has_time? # add start_time inputs
					res[1] << symbol_item(:clock)
					res[1] << { kind: :time_box, key: :hour, hour: @event.hour, mins: @event.min, mandatory: true }
				end
				h_fields = event_form_hidden_inputs(copy ? nil : @event&.team_id)
				h_fields << hidden_input(:kind, @event.kind)
				res << h_fields
			else
				res[0] << normal_button({ kind: :link, symbol: symbol_hash(:calendar), url: path_for(@event, format: :ics), title: Event.act(:add) })
				res[0] << { kind: :string, value: @event.date_string }
				if @event.specific.has_time?
					res[1] << gap_item if @task
					res[1] << symbol_item(:clock, { title: Calendar.fld(:time) })
					res[1] << { kind: :string, value: @event.time_string }
				end
			end
		end

		# dropdown button definition to create a new Event
		def new_event_button(obj)
			return nil unless @policy.new?	# cannot add events otherwise

			case obj
			when Club	# Club-wide event
				normal_button({ kind: :add, url: new_path_for(@club, :event, kind: :holiday), frame: :modal })
			when Team # new team event
				button = { kind: :add, name: "add-event", options: [] }
				button[:options] << { label: Event.kind_label(:training), url: new_path_for(@team, :event, kind: :training), data: { turbo_frame: :modal } }
				button[:options] << { label: Event.kind_label(:match), url: new_path_for(@team, :event, kind: :match), data: { turbo_frame: :modal } }
				button[:options] << { label: Event.kind_label(:holiday), url: new_path_for(@team, :event, kind: :holiday), data: { turbo_frame: :modal } }
				dropdown_button(button, class: "bg-white")
			else
				nil
			end
		end
end
