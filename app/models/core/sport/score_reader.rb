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
# Generic accessor for Sport scores
class Sport
	class ScoreReader
		def initialize(sport)
			@sport = sport
		end

		def match_score(event_id)
			score = {}
			total = initial_total_score
			stats = scoring_stats(event_id)
			return { tot: total } if stats.blank?

			@sport.catalog(:periods).each do |period|
				read_period_score(period:, stats:, score:, total:)
			end

			Rails.logger.debug {
				"match_score(#{event_id}): scoring=#{@sport.scoring.inspect} " \
				"enum=#{@sport.statistics.enum.inspect} " \
				"scoring_concept=#{@sport.statistics.enum[@sport.scoring[:points]].inspect} " \
				"stats_found=#{stats.size} kinds=#{stats.map(&:kind).uniq.inspect} " \
				"concepts=#{stats.map(&:concept).uniq.inspect}"
			}

			score[:tot] ||= total
			score
		end

		private
			def initial_total_score
				{ ours: 0, opps: 0 }
			end

			def scoring_stats(event_id)
				Stat.fetch(
					event_id:,
					concept: @sport.statistics.enum[@sport.scoring[:points]],
					create: false
				)
			end

			def period_score(period:, stats:, **owner)
				Stat.fetch(period:, stats:, create: false, **owner).first&.value
			end

			def read_period_score(period:, stats:, score:, total:)
				return if period.key == :tot

				ours = period_score(period: period.id, kind: :team,  stats:)
				opps = period_score(period: period.id, kind: :rival, stats:)
				return if ours.nil? && opps.nil?

				ours = ours.to_i
				opps = opps.to_i

				score[period.key] = { ours:, opps: }
				@sport.send(:accumulate_score, total:, ours:, opps:)
			end
	end
end
