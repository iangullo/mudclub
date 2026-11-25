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
# Generic builder for Sport UI fields
class Sport
	class FieldBuilder
		def initialize(sport)
			@sport = sport
		end

		def label_item(value, **opts)
			{ kind: :label, value:, **opts }
		end

		def stat_label(label, _abbr = true)
			{ kind: :side_cell, value: label, align: "middle", class: "border px-1 py-1" }
		end

		def stat_field(prefix, stats, stat, edit: false)
			value = stat_value(stats, stat)

			unless edit
				{ kind: :normal,
					value: format_stat_value(stat, value),
					align: "right" }
			else
				{ kind:  :number_box,
					key:   "#{prefix}#{stat.id}",
					value:,
					min:   stat[:minimum],
					max:   stat[:maximum],
					size:  stat[:size],
					units: stat[:units],
					step:  stat[:step] }.compact
			end
		end

		def stat_value(stats, stat)
			Stat.fetch(concept: stat.id, stats:, create: false).first&.value.to_i
		end

		private
			def format_stat_value(stat, value)
				case stat[:format]
				when :time then @sport.time_string(value)
				else            value
				end
			end
	end
end
