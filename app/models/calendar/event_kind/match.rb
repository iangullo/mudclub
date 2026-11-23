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
# Match events
#
# app/models/calendar/event_kind/match.rb
class EventKind
	class Match < Base
		def self.slugs = %i[match]
		def slug       = :match
		def show_cols  = nil
		def form_cols  = 2

		def show_fields(view, policy:, team: nil, cal: nil)
			sport.match_show(event)
		end

		def show_table(view, policy:, team: nil, cal: nil)
			roster_table(view, edit: false)
		end

		def form_fields(view, policy:, team: nil, cal: nil, new: false)
			sport.match_form(event, new:)
		end

		def form_table(view, policy:, team: nil, cal: nil, new: false)
			new ? nil : roster_table(view, edit: true)
		end

		def header_fragments(view, res:, policy:, form: nil, cols: nil, **)
			res << [ { kind: :subtitle, value: category.name }, view.gap_item ]
			res << [ view.gap_item(1), view.string_item("#{division.name} (#{season.name})"), view.gap_item ]

			if form
				res[0][1][:cols] = nil
				res << [ view.gap_item(1),
								{ kind: :side_cell, value: event.term(:match), align: :left, cols: 2 } ]
				res << [ view.symbol_item(:location, { title: Location.label }, align: :right),
								{ kind: :select_collection, key: :location_id, options: Location.home,
									value: event.location_id,
									s_target: "data-match-location-target='locationId'", cols: 6 },
								view.hidden_input(:homecourt_id, team.homecourt_id,
																	i_data: { match_location_target: "homeCourtId" }) ]
			else
				if event.location.gmaps_url
					res.last << view.normal_button(
						{ kind: :location, symbol: :gmaps, url: event.location.gmaps_url, label: event.location.name },
						cols: 2
					)
				end
				if policy.attendance?
					res << [ view.gap_item(1),
									{ kind: :side_cell, value: team.term(:match), align: :left, cols: 2 },
									view.normal_button(
										{ kind: :link, symbol: :attendance, label: team.term(:match, :roster),
											url: view.event_action_path(:attendance, event:), frame: :modal },
										align: :left, cols: 2
									) ]
					res << view.gap_row
				end
			end
			res
		end

		private
			# `match_roster_table` was already kind-specific — move its body here.
			def roster_table(view, edit:)
				rule  = sport.rules.key(team.category.rules)
				if (outings = sport.match_outings(rule))
					table = sport.outings_table(event, outings, edit:)
					table[:controller] = "outings" if table
					return table
				end
				sport.stats_table(event, edit:)
			end
	end
end
