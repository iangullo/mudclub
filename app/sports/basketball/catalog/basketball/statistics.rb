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
#
# Catalog::Basketball::Statistics
#
# Canonical basketball statistics.
#
# id       -> persistent database identifier
# family   -> logical family for grouping/filtering
# kind     -> semantic role within its family
# value    -> point value (where applicable)
# usage    -> expected usage
# editable -> manually editable
#
class Catalog::Basketball::Statistics < Catalog::Base
	domain "basketball"

	CATALOG = {

		#
		# ----------------------------------------------------------------------
		# Scoring
		# ----------------------------------------------------------------------
		#

		sec: {
			id: 0,
			family: :scoring,
			kind: :time,
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			maximum: 3960,
			size: 3,
			units: "\"",
			step: 1
		},

		pts: {
			id: 1,
			family: :scoring,
			kind: :score,
			points: 1,
			usage: %i[match training reports boxscore],
			editable: false,
			minimum: 0
		},

		pta: {
			id: 2,
			family: :scoring,
			kind: :attempt,
			usage: %i[reports],
			editable: false,
			minimum: 0
		},

		#
		# ----------------------------------------------------------------------
		# Free throws
		# ----------------------------------------------------------------------
		#

		fta: {
			id: 3,
			family: :shooting,
			kind: :attempt,
			points: 1,
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		ftm: {
			id: 4,
			family: :shooting,
			kind: :made,
			points: 1,
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		#
		# ----------------------------------------------------------------------
		# Field goals (computed)
		# ----------------------------------------------------------------------
		#

		fga: {
			id: 5,
			family: :shooting,
			kind: :attempt,
			components: %i[t2a t3a],
			usage: %i[reports],
			editable: false,
			minimum: 0
		},

		fgm: {
			id: 6,
			family: :shooting,
			kind: :made,
			components: %i[t2m t3m],
			usage: %i[reports],
			editable: false,
			minimum: 0
		},

		#
		# ----------------------------------------------------------------------
		# Near basket
		# ----------------------------------------------------------------------
		#

		tza: {
			id: 9,
			family: :shooting,
			kind: :attempt,
			points: 2,
			usage: %i[training reports],
			editable: true,
			minimum: 0,
			step: 1
		},

		tzm: {
			id: 10,
			family: :shooting,
			kind: :made,
			points: 2,
			usage: %i[training reports],
			editable: true,
			minimum: 0,
			step: 1
		},

		#
		# ----------------------------------------------------------------------
		# Mid-range
		# ----------------------------------------------------------------------
		#

		tma: {
			id: 11,
			family: :shooting,
			kind: :attempt,
			points: 2,
			usage: %i[training reports],
			editable: true,
			minimum: 0,
			step: 1
		},

		tmm: {
			id: 12,
			family: :shooting,
			kind: :made,
			points: 2,
			usage: %i[training reports],
			editable: true,
			minimum: 0,
			step: 1
		},

		#
		# ----------------------------------------------------------------------
		# Two-point shots
		# ----------------------------------------------------------------------
		#

		t2a: {
			id: 7,
			family: :shooting,
			kind: :attempt,
			points: 2,
			components: %i[tza tma],
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		t2m: {
			id: 8,
			family: :shooting,
			kind: :made,
			points: 2,
			components: %i[tzm tmm],
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		#
		# ----------------------------------------------------------------------
		# Three-point shots
		# ----------------------------------------------------------------------
		#

		t3a: {
			id: 13,
			family: :shooting,
			kind: :attempt,
			points: 3,
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		t3m: {
			id: 14,
			family: :shooting,
			kind: :made,
			points: 3,
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		#
		# ----------------------------------------------------------------------
		# Rebounding
		# ----------------------------------------------------------------------
		#

		drb: {
			id: 15,
			family: :rebounding,
			kind: :defensive,
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		orb: {
			id: 16,
			family: :rebounding,
			kind: :offensive,
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		trb: {
			id: 17,
			family: :rebounding,
			kind: :total,
			components: %i[drb orb],
			usage: %i[reports boxscore],
			editable: false,
			minimum: 0
		},

		#
		# ----------------------------------------------------------------------
		# Playmaking
		# ----------------------------------------------------------------------
		#

		ast: {
			id: 18,
			family: :playmaking,
			kind: :assist,
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		to: {
			id: 20,
			family: :playmaking,
			kind: :turnover,
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		#
		# ----------------------------------------------------------------------
		# Defence
		# ----------------------------------------------------------------------
		#

		stl: {
			id: 19,
			family: :defense,
			kind: :steal,
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		blk: {
			id: 21,
			family: :defense,
			kind: :block,
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		bla: {
			id: 22,
			family: :defense,
			kind: :blocked_against,
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		#
		# ----------------------------------------------------------------------
		# Discipline
		# ----------------------------------------------------------------------
		#

		pfc: {
			id: 23,
			family: :discipline,
			kind: :committed,
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		pfr: {
			id: 24,
			family: :discipline,
			kind: :received,
			usage: %i[match training reports boxscore],
			editable: true,
			minimum: 0,
			step: 1
		},

		#
		# ----------------------------------------------------------------------
		# Outings
		# ----------------------------------------------------------------------
		#

		q1: {
			id: 25,
			family: :outings,
			kind: :period,
			usage: %i[match],
			editable: true,
			minimum: 0,
			maximum: 1
		},

		q2: {
			id: 26,
			family: :outings,
			kind: :period,
			usage: %i[match],
			editable: true,
			minimum: 0,
			maximum: 1
		},

		q3: {
			id: 27,
			family: :outings,
			kind: :period,
			usage: %i[match],
			editable: true,
			minimum: 0,
			maximum: 1
		},

		q4: {
			id: 28,
			family: :outings,
			kind: :period,
			usage: %i[match],
			editable: true,
			minimum: 0,
			maximum: 1
		},

		q5: {
			id: 29,
			family: :outings,
			kind: :period,
			usage: %i[match],
			editable: true,
			minimum: 0,
			maximum: 1
		},

		q6: {
			id: 30,
			family: :outings,
			kind: :period,
			usage: %i[match],
			editable: true,
			minimum: 0,
			maximum: 1
		},

		ot: {
			id: 31,
			family: :outings,
			kind: :overtime,
			usage: %i[match],
			editable: true,
			minimum: 0
		}

	}.freeze
end
