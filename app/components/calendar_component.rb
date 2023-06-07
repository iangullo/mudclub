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
# frozen_string_literal: true

# CalendarComponent - manage a calendar view as ViewComponent using TailwindCSS
# Each calendar is defined by:
#   => start_date: (expected to be the first day of a month)
#		=> events: list of events to be rendered. With each event object having:
#			=> start_time, end_time and kind
# optional: associated form object (if needed)

class CalendarComponent < ApplicationComponent
	# start calendar
	def initialize(start_date:, events: nil, anchor: nil, obj: nil, user: nil, create_url: nil)
		@start_date = start_date
		@events     = events
		@anchor     = anchor ? anchor : request.path
		@iscope_cls = "bg-gray-100 text-gray-500 text-center"
		@oscope_cls = "bg-gray-500 text-gray-100 text-center"
		@cells      = new_canvas(start_date:)
		@back_link  = set_back_button(events:)
		@fwd_link   = set_fwd_button(events:)
		parse_events(events:, obj:, user:, create_url:)
	end

	private
		# prepare row/column canvas of @cells depending on
		# calendar view start_date:
		def new_canvas(start_date:)
			@c_month = start_date.month
			@c_cols  = 7	# 7 days per week
			f_date = start_date.at_beginning_of_month
			f_date = f_date.prev_occurring(:monday) unless f_date.wday==1
			l_date = start_date.at_end_of_month
			l_date = l_date.next_occurring(:sunday) unless l_date.wday==7
			@c_rows = ((l_date - f_date)/@c_cols).ceil
			@dayname = []	# host day names
			1.upto(@c_cols) { |j| @dayname << I18n.t("calendar.daynames_a")[j] if @c_cols > 1 }
			@cells   = canvas_cells(f_date:)
		end

		# cells of canvas have strong dependency on calendar scope
		def canvas_cells(f_date:)
			@cells = []	# prepare cell canvas (organized as [row][column])
			1.upto(@c_rows) do |i| # one cell per day
				row = []	# new calendar row
				1.upto(@c_cols) do |j|
					in_scope = (f_date.month==@start_date.month)
					n_cell = {c_class: (in_scope ? @iscope_cls : @oscope_cls), date: f_date, events: []}
					row[j] = n_cell	# add new cell to the row
					f_date = f_date + 1 # check next day
				end
				@cells[i] = row	# add row
			end
			@cells
		end

		# Parse a collection of Events and map to the canvas
		def parse_events(events: nil, obj: nil, user: nil, create_url: nil)
			events.each do |event|	# find the day for each event
				e_cell = get_cell(e_date: event.start_date)
				if e_cell
					c_event = c_event_init(event:)
					e_cell[:events] << c_event
				end
			end if events
			add_empty_buttons(obj:, user:, create_url:) if obj and user and create_url
		end

		# returns cell for a specific date
		def get_cell(e_date:)
			1.upto(@c_rows) do |i|
				@cells[i].each do |e_cell|
					return e_cell if e_cell and e_cell[:date]==e_date # found it!
				end
			end
			return nil
		end

		# determine event_color depending on event kind
		def c_event_init(event:)
			c_event = {id: event.id}
			case event.kind
			when "match"
				sc = event.score(mode: 0)	# our team first
				c_event[:icon] = "match.svg"
				c_event[:home] = event.home? ? sc[:home] : sc[:away]
				c_event[:away] = event.home? ? sc[:away] : sc[:home]
				if sc[:home][:points] > sc[:away][:points]
					b_color = "green"
				elsif sc[:home][:points] < sc[:away][:points]
					b_color = "red"
				else
					b_color = "yellow"
				end
			when "train"
				c_event[:icon]  = "training.svg"
				c_event[:label] = event.to_s
				b_color         = "blue"
			when "rest"
				c_event[:icon]  = "rest.svg"
				c_event[:label] = event.to_s
				c_event[:data]  = {turbo_frame: "modal"	}
				b_color         = "gray"
			end
			c_event[:b_class] = "bg-#{b_color}-300 rounded-lg border px py hover:text-white hover:bg-#{b_color}-700 text-sm"
			c_event[:t_class] = "bg-#{b_color}-700 rounded-lg invisible inline-block font-light border border-gray-200 border shadow-sm m-2 text-white text-sm"
			c_event[:l_class] = "hover:text-white hover:bg-#{b_color}-700"
			c_event
		end

		# add create event buttons to empty canvas cells
		def add_empty_buttons(obj:, user:, create_url:)
			@add_btn = []
			1.upto(@c_rows) do |i|
				row = []
				cday = Date.current
				1.upto(@c_cols) do |j|
					if @cells[i][j][:events].empty? and @cells[i][j][:date]>=cday # add a create_event button
						row[j] = add_event_button(obj:, for_season: (obj.class==Season), i:, j:, user:, create_url:)
					else
						row[j] = nil
					end
					@add_btn[i] = row
				end
			end
		end

		# dropdown button definition to create a new Event
		def add_event_button(obj:, for_season: nil, i:, j:, user:, create_url:)
			c_url = create_url + "?event[start_date]=#{@cells[i][j][:date]}"
			cname = "add_btn_#{i}_#{j}"
			if for_season and user.admin? # new season event
				return ButtonComponent.new(button: {kind: "add", name: cname, url: c_url + "&event[kind]=rest&event[team_id]=0", frame: "modal"})
			elsif obj.has_coach(user.person.coach_id) # new team event
				c_url  = c_url + "&event[team_id]=#{obj.id}"
				button = {kind: "add", name: cname, options: []}
				button[:options] << {label: I18n.t("train.single"), url: c_url + "&event[kind]=train", data: {turbo_frame: :modal}}
				button[:options] << {label: I18n.t("match.single"), url: c_url + "&event[kind]=match", data: {turbo_frame: :modal}}
				button[:options] << {label: I18n.t("rest.single"), url: c_url + "&event[kind]=rest", data: {turbo_frame: :modal}}
				return DropdownComponent.new(button: button)
			else
				return nil
			end
		end

		# return backbutton if we do not exceed beginning of events season
		def set_back_button(events:)
			e_first = events&.first	# we have a first event?
			e_date  = e_first ? e_first.team.season.start_date : Season.latest.start_date
			if e_date
				c_date = @cells[1][1][:date]
				return nil if c_date <= e_date	# we have reached beginning of season
			end
			ButtonComponent.new(button: {kind: "back", label: "", url: @anchor.split('?').first + "?start_date=" + (@start_date - 1.month).to_s})
		end

		# return fwdbutton depending on end_date
		def set_fwd_button(events:)
			e_last = events&.last	# we have a last event?
			e_date = e_last ? e_last.team.season.end_date : Season.latest.end_date
			if e_date
				c_date = @cells.last.last[:date]
				return nil if c_date >= e_date	# we have reached end of season
			end
			ButtonComponent.new(button: {kind: "forward", label: "", url: @anchor.split('?').first + "?start_date=" + (@start_date + 1.month).to_s})
		end
end
