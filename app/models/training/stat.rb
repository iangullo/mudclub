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
class Stat < ApplicationRecord
	localized_as "training.stat"

	#-------------------------------------
	# Class relationships
	#-------------------------------------
	self.inheritance_column = "not_sti"
	belongs_to :event
	belongs_to :athlete, class_name: "Assignment", foreign_key: :athlete_id, optional: true

	# DEPRECATED: player_id is a legacy column. It is preserved for read-only
	# compatibility until v2.1 and will be dropped once all callers use athlete.
	belongs_to :player, optional: true  # id==0 => team stat; id==-1 => rival stat

	#-------------------------------------
	# Included Modules
	#-------------------------------------
	include Kinded

	#-------------------------------------
	# Validations
	#-------------------------------------
	validates :kind, presence: true
	validate  :athlete_consistency

	# -------------------------------------------------------------------------
	# Scopes
	# -------------------------------------------------------------------------
	scope :real,         -> { where("id>0") }
	scope :for_event,    ->(e) { where(event_id: e.respond_to?(:id) ? e.id : e) }
	scope :for_team,     -> { kind_team }
	scope :for_rival,    -> { kind_rival }
	scope :for_athletes, -> { kind_athlete }
	scope :for_athlete,  ->(a) { where(athlete_id: a.respond_to?(:id) ? a.id : a) }
	scope :for_concept,  ->(c) { where(concept: c.to_i) }

	# DEPRECATED (removal ~v2.1) — delegates to the new scopes.
	scope :for_players, -> {
	  Deprecated.warn!(:Stat, :for_players)
		kind_athlete
	}
	scope :for_player,  ->(p_id) {
	  Deprecated.warn!(:Stat, :for_player)
		where(player_id: p_id)
	}

	# ---------------------------------------------------------------------------
	# Accessors
	# ---------------------------------------------------------------------------
	def concept = self[:concept]
	def value   = self[:value]

	class << self
		# Unified fetch
		# Fetch stats scoped by event / period / owner / concept.
		#
		# stats:  – pass nil (default) to let the DB do the filtering,
		#           or an Array of already-loaded stats to filter in memory.
		#
		# Returns an Array (matches historical contract).
		def fetch(event_id: nil, period: nil, kind: nil, athlete_id: nil, concept: nil, stats: nil, create: true, **legacy)
			if (player_id = legacy[:player_id])
				Deprecated.warn!(:Stat, :fetch)
				kind, athlete_id = translate_player_id(player_id, event_id, kind, athlete_id)
			end

			results =
				if stats.is_a?(Array)
					filter_in_memory(stats.dup,
													event_id:, period:, kind:, athlete_id:, concept:)
				else
					fetch_stats(stats, event_id:, period:, kind:, athlete_id:, concept:)
				end

			if create && results.empty?
				resolved_kind =
					if kind
						kind.to_sym
					elsif athlete_id.present?
						:athlete
					else
						:team
					end

				if resolved_kind == :athlete && athlete_id.blank?
					raise ArgumentError,
								"Stat.fetch(kind: :athlete) requires athlete_id:"
				end

				results << Stat.new(
					build_attrs(event_id:, period:, concept:,
											kind: resolved_kind, athlete_id:, value: 0)
				)
			end

			results
		end

		# Build the attribute hash for a new Stat, keeping the legacy player_id
		# sentinel in sync while the column still exists.
		#
		# DEPRECATED (removal ~v3.x): the `when :team/:rival` arms are legacy
		# dual-write for old readers. Once stats.player_id is dropped, this
		# method collapses to a plain hash.
		def build_attrs(event_id:, period:, concept:, kind:, athlete_id: nil, value: 0)
			attrs = { event_id:, period:, concept:, kind:, value: }

			case kind.to_sym
			when :athlete
				attrs[:athlete_id] = athlete_id
			when :team
				attrs[:player_id] = 0  if column_names.include?("player_id")
			when :rival
				attrs[:player_id] = -1 if column_names.include?("player_id")
			end

			attrs
		end

		# ---------------------------------------------------------------------------
		# Filter helpers
		# ---------------------------------------------------------------------------
		def by_event(e_id, stats = Stat.real)           = stats.select { |s| s.event_id == e_id }
		def by_kind(kind, stats = Stat.real)            = stats.select { |s| s.kind == kind.to_s }
		def by_athlete(a_id, stats = Stat.for_athletes) = stats.select { |s| s.athlete_id == a_id }
		def by_period(period, stats = Stat.real)        = stats.select { |s| s.period == period }
		def by_concept(concept, stats = Stat.real)      = stats.select { |s| s.concept == concept }
		def by_q(q, stats = Stat.for_athletes)          = stats.select { |s| s[:concept] == "q#{q}" }

		# DEPRECATED (removal ~v2.1)
		def by_player(player_id, stats = Stat.for_athletes)
			Rails.deprecator.warn("Stat.by_player is deprecated — use by_athlete")
			stats.select { |s| s.player_id == player_id }
		end

		# Callers may pass strings from params.
		def translate_player_id(player_id, event_id, kind, athlete_id)
			pid = player_id.to_i
			return [ :team,  nil ] if pid == 0
			return [ :rival, nil ] if pid == -1

			# Athlete: resolve through the event's team, if the caller gave us an event.
			return [ kind, athlete_id ] if athlete_id.present?

			event  = Event.find_by(id: event_id)
			player = Player.find_by(id: pid)

			athlete =
				if event&.team && player&.person_id
					Assignment.joins(:membership)
										.where(team: event.team, kind: :athlete)
										.find_by(memberships: { person_id: player.person_id })
				end

			unless athlete
				Rails.deprecator.warn(
					"Stat.fetch could not translate player_id=#{pid} to an athlete — " \
					"athlete stat will not be found or created"
				)
			end

			[ :athlete, athlete&.id ]
		end

		private
			# query the database to get stats
			def fetch_stats(base, event_id:, period:, kind:, athlete_id:, concept:)
				relation = base.nil? ? Stat.real : base
				relation = relation.where(event_id:)      if event_id
				relation = relation.where(kind:)          if kind
				relation = relation.where(athlete_id:) if athlete_id
				relation = relation.where(period:)        unless period.nil?
				relation = relation.where(concept:)       if concept
				relation.to_a
			end

			# stats were pre-fetched, just filtering through them
			def filter_in_memory(stats, event_id: nil, period: nil, kind: nil, athlete_id: nil, concept: nil)
				stats = stats.select { |s| s.event_id == event_id }           if event_id
				stats = stats.select { |s| s.kind == kind.to_s }              if kind
				stats = stats.select { |s| s.athlete_id == athlete_id } if athlete_id
				stats = stats.select { |s| s.period == period } unless period.nil?
				stats = stats.select { |s| s.concept == concept }             if concept
				stats
			end
	end

	private_class_method :fetch_stats, :filter_in_memory

	# ---------------------------------------------------------------------------
	private
		def athlete_consistency
			if kind_athlete? && athlete_id.blank?
				errors.add(:athlete, :blank)
			elsif !kind_athlete? && athlete_id.present?
				errors.add(:athlete, :present)
			end
		end
end
