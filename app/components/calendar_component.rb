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
	def initialize(start_date:, events: nil, anchor: nil)
		@start_date = start_date
		@events     = events
		@anchor     = anchor ? anchor : request.path
		@iscope_cls = "bg-gray-100 text-gray-500 text-center border-1"
		@oscope_cls = "bg-gray-500 text-gray-100 text-center border-1"
		@cells      = new_canvas
		@back_link  = ButtonComponent.new(button: {kind: "back", label: "", url: @anchor.split('?').first + "?start_date=" + (@start_date - 1.month).to_s})
		@fwd_link   = ButtonComponent.new(button: {kind: "forward", label: "", url: @anchor.split('?').first + "?start_date=" + (@start_date + 1.month).to_s})
		parse_events(events:)
	end

	private
	# prepare row/column canvas of @cells depending on
	# calendar view start_date:
	def new_canvas
		@c_month = @start_date.month
		@c_cols  = 7	# 7 days per week
		f_date = @start_date.at_beginning_of_month
		f_date = f_date.prev_occurring(:monday) unless f_date.wday==1
		l_date = @start_date.at_end_of_month
		l_date = l_date.next_occurring(:sunday) unless l_date.wday==7
		@c_rows = ((l_date - f_date)/@c_cols).ceil
		@dayname = []	# host day names
		1.upto(@c_cols) { |j| @dayname << I18n.t("calendar.daynames_a")[j] if @c_cols > 1 }
		@cells   = canvas_cells(f_date:)
	end

	# cells of canvas have strong dependency on calendar scope
	def canvas_cells(f_date:)
		@cells = []	# prepare cell canvas (organized as [row][column])
		1.upto(@c_rows) { |i| # one cell per day
			row = []	# new calendar row
			1.upto(@c_cols) { |j|
				in_scope = (f_date.month==@start_date.month)
				n_cell = {c_class: (in_scope ? @iscope_cls : @oscope_cls), date: f_date, events: []}
				row[j] = n_cell	# add new cell to the row
				f_date = f_date + 1 # check next day
			}
			@cells[i] = row	# add row
		}
		@cells
	end

	# Parse a collection of Events and map to the canvas
	def parse_events(events: nil)
		events.each { |event|	# find the day for each event
			e_cell = get_cell(e_date: event.start_date)
			if e_cell
				c_event = c_event_init(event:)
				e_cell[:events] << c_event
			end
		} if events
	end

	# returns cell for a specific date
	def get_cell(e_date:)
		1.upto(@c_rows) { |i|
			@cells[i].each { |e_cell|
				return e_cell if e_cell and e_cell[:date]==e_date # found it!
			}
		}
		return nil
	end

	# determine event_color depending on event kind
	def c_event_init(event:)
		c_event = {id: event.id}
		if event.match?
			sc = event.score(mode: 0)	# our team first
			c_event[:home] = event.home? ? sc[:home] : sc[:away]
			c_event[:away] = event.home? ? sc[:away] : sc[:home]
			if sc[:home][:points] > sc[:away][:points]
				b_color = "green"
			elsif sc[:home][:points] < sc[:away][:points]
				b_color = "red"
			else
				b_color = "yellow"
			end
		else
			c_event[:label] = event.to_s
			b_color         = event.train? ? "blue" : "gray"
		end
		c_event[:b_class] = "bg-#{b_color}-300 rounded-lg border px py hover:text-white hover:bg-#{b_color}-700 text-sm"
		c_event[:l_class] = "hover:text-white hover:bg-#{b_color}-700"
		c_event
	end
end
