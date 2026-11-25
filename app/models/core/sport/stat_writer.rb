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
# Generic updater for Sport stats
class Sport
	class StatWriter
		def initialize(sport)
			@sport = sport
		end

		def update_stat(event_id:, concept:, value:, period: 0, kind: :athlete, athlete_id: nil, **legacy)
			if legacy.key?(:player_id)
				kind, athlete_id = Stat.translate_player_id(legacy[:player_id].to_i, event_id, kind, athlete_id)
			end

			cid = concept_id(concept)
			if (stat = Stat.fetch(event_id:, period:, kind:, athlete_id:, concept: cid, create: false).first)
				stat.update!(value: value.to_i)
				stat
			else
				begin
					Stat.create!(Stat.build_attrs(
						event_id:, period:, concept: cid,
						kind:, athlete_id:, value: value.to_i
					))
				rescue ActiveRecord::RecordNotUnique
					Stat.fetch(event_id:, period:, kind:, athlete_id:, concept: cid, create: false)
							.first&.update!(value: value.to_i)
				end
			end
		end

		def update_stats(event_id:, stats_data:)
			stats_data = stats_data.to_unsafe_h if stats_data.respond_to?(:to_unsafe_h)
			stats_data = stats_data.to_h unless stats_data.is_a?(Hash)

			scoring_concept = @sport.statistics.enum[@sport.scoring[:points]]
			periods_seen    = Hash.new(false)
			period_sums     = Hash.new(0)
			athlete_sums    = Hash.new(0)

			stats_data.each_pair do |key, raw|
				next if raw.blank?

				parsed = parse_stat_key(key)
				next unless parsed

				owner, period, concept = parsed
				kind, athlete_id       = resolve_stat_owner(owner, event_id)
				next unless kind

				update_stat(event_id:, period:, concept:, kind:, athlete_id:, value: raw)

				if owner.to_s.in?(%w[ours opps]) && period.positive?
					periods_seen[owner.to_s]  = true
					period_sums[owner.to_s]  += raw.to_i
				elsif athlete_id.present?
					athlete_sums[concept.to_i] += raw.to_i
				end
			end

			reconcile_totals(
				event_id:, stats_data:, scoring_concept:,
				periods_seen:, period_sums:, athlete_sums:
			)
		end

		private
			def concept_id(concept)
				case concept
				when Integer        then concept
				when Symbol         then @sport.statistics.enum[concept]
				when Catalog::Entry then concept.id
				when String
					concept.match?(/\A\d+\z/) ? concept.to_i : @sport.statistics.enum[concept.to_sym]
				else
					concept.to_i
				end
			end

			# "<owner>_<period>_<concept>" — period resolved to a catalog id.
			def parse_stat_key(key)
				parts = key.to_s.split("_")
				return nil unless parts.size == 3

				owner, period_str, concept = parts
				period = resolve_period(period_str)
				return nil if period.nil?

				[ owner, period, concept ]
			end

			def resolve_stat_owner(owner, event_id)
				case owner.to_s
				when "ours" then [ :team,  nil ]
				when "opps" then [ :rival, nil ]
				else
					return [ :athlete, owner ] if @sport.send(:uuid?, owner)
					Stat.translate_player_id(owner.to_i, event_id, nil, nil)
				end
			end

			def resolve_period(period_str)
				return period_str.to_i if period_str.match?(/\A\d+\z/)

				@sport.catalog(:periods).enum[period_str.to_sym]
			end

			def reconcile_totals(event_id:, stats_data:, scoring_concept:,
													periods_seen:, period_sums:, athlete_sums:)
				(athlete_sums.keys | [ scoring_concept ]).compact.each do |cid|
					value =
						if cid == scoring_concept
							team_scoring_total(stats_data:, periods_sum: period_sums["ours"],
																athletes_sum: athlete_sums[cid] || 0)
						else
							athlete_sums[cid]
						end

					write_total(event_id:, kind: :team, concept: cid, value:)
				end

				reconcile_rival_total(
					event_id:, stats_data:, scoring_concept:,
					periods_seen:, period_sums:
				)
			end

			def reconcile_rival_total(event_id:, stats_data:, scoring_concept:,
																periods_seen:, period_sums:)
				if periods_seen["opps"]
					write_total(
						event_id:, kind: :rival, concept: scoring_concept,
						value: rival_scoring_total(stats_data:, periods_sum: period_sums["opps"])
					)
				elsif stats_data.key?("opps_tot_1")
					manual = stats_data["opps_tot_1"]
					if manual.blank?
						Stat.where(event_id:, period: 0, kind: :rival, concept: scoring_concept)
								.destroy_all
					else
						write_total(event_id:, kind: :rival, concept: scoring_concept,
												value: manual.to_i)
					end
				end
			end

			def team_scoring_total(stats_data:, periods_sum:, athletes_sum:)
				total  = periods_sum + athletes_sum
				manual = stats_data["ours_tot_1"]

				if total.zero? && manual.present? && manual.to_i.positive?
					manual.to_i
				else
					total
				end
			end

			def rival_scoring_total(stats_data:, periods_sum:)
				manual = stats_data["opps_tot_1"]
				if periods_sum.zero? && manual.present? && manual.to_i.positive?
					manual.to_i
				else
					periods_sum
				end
			end

			def write_total(event_id:, kind:, concept:, value:)
				scope = Stat.where(event_id:, period: 0, kind:, concept:)
				if (stat = scope.first)
					stat.update!(value:) unless stat.value == value
				else
					Stat.create!(Stat.build_attrs(event_id:, period: 0, concept:, kind:, value:))
				end
			end
	end
end
