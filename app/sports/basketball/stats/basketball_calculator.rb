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
# Calculations of Basketball Stats
module Stats
	class BasketballCalculator
		SUB_ZONE_KEYS = %i[tza tzm tma tmm].freeze

		def initialize(sport)
			@sport = sport
		end

		def parse(event, stats_data)
			event.athletes.each do |athlete|
				parse_athlete(athlete.id, stats_data)
			end
		end

		def compute_shooting_totals(event_id, athlete_id, stats)
			statistics = @sport.statistics

			%i[fgm fga].each do |concept|
				entry = statistics.fetch(concept)

				total = entry.components.sum do |component|
					Stat.fetch(concept: statistics.enum[component], period: 0, stats:)
							.first&.value.to_i
				end

				cached = stats.find { |s| s.concept == entry.id && s.period == 0 }

				if cached
					cached.update!(value: total) if cached.value != total
				else
					stats << Stat.create!(
						Stat.build_attrs(
							event_id:, period: 0, concept: entry.id,
							kind: :athlete, athlete_id:, value: total
						)
					)
				end
			end
		end

		private
			def parse_athlete(athlete_id, stats)
				statistics = @sport.statistics
				prefix     = "#{athlete_id}_0_"
				values     = Hash.new(0)
				submitted  = Set.new

				stats.each_pair do |key, raw|
					next unless key.start_with?(prefix)

					concept_id = key.delete_prefix(prefix).to_i
					entry = statistics.entry(concept_id)
					next unless entry

					values[entry.key] = raw.to_i
					submitted << entry.key
				end

				2.times do
					statistics.each do |entry|
						comps = entry[:components]
						next unless comps&.any? { |c| submitted.include?(c) }

						values[entry.key] = comps.sum { |c| values[c] }
						submitted << entry.key
					end
				end

				scoring_shots = statistics.where(family: :shooting).select do |e|
					e[:points] && SUB_ZONE_KEYS.exclude?(e.key)
				end

				values[:pta] = scoring_shots.select { |e| e[:kind] == :attempt }.sum { |e| values[e.key] * e[:points] }
				values[:pts] = scoring_shots.select { |e| e[:kind] == :made }.sum { |e| values[e.key] * e[:points] }

				%i[pta pts fga fgm t2a t2m trb].each do |key|
					id = statistics.enum[key]
					stats["#{prefix}#{id}"] = values[key] if id
				end
			end
	end
end
