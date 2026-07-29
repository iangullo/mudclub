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
# #
# Basketball diagram objects.
#
# Defines every object and action available when creating
# basketball diagrams.
#
class Catalog::Basketball::Objects < Catalog::Base
	domain "sport.basketball"

	CATALOG = {

		#
		# ----------------------------------------------------------------------
		# Symbols
		# ----------------------------------------------------------------------
		#

		attacker: {
			id: 1,

			category: :symbol,
			group: :people,

			editor: {
				action: :add,
				options: {
					label: "?"
				}
			},

			description: "Attacking player."
		},

		defender: {
			id: 2,

			category: :symbol,
			group: :people,

			editor: {
				action: :add,
				options: {
					label: "n"
				}
			},

			description: "Defending player."
		},

		coach: {
			id: 3,

			category: :symbol,
			group: :people,

			editor: {
				action: :add
			},

			description: "Coach."
		},

		cone: {
			id: 4,

			category: :symbol,
			group: :equipment,

			editor: {
				action: :add
			},

			description: "Training cone."
		},

		ball: {
			id: 5,

			category: :symbol,
			group: :ball,

			editor: {
				action: :add
			},

			description: "Basketball."
		},

		#
		# ----------------------------------------------------------------------
		# Actions
		# ----------------------------------------------------------------------
		#

		move: {
			id: 10,

			category: :action,
			group: :movement,

			editor: {
				action: :draw
			},

			path: {
				curve: true,
				style: :solid,
				ending: :arrow
			},

			description: "Player movement."
		},

		pass: {
			id: 11,

			category: :action,
			group: :ball,

			editor: {
				action: :draw
			},

			path: {
				curve: false,
				style: :dashed,
				ending: :arrow
			},

			description: "Ball pass."
		},

		dribble: {
			id: 12,

			category: :action,
			group: :ball,

			editor: {
				action: :draw
			},

			path: {
				curve: true,
				style: :wavy,
				ending: :arrow
			},

			description: "Dribbling."
		},

		shot: {
			id: 13,

			category: :action,
			group: :ball,

			editor: {
				action: :draw
			},

			path: {
				curve: false,
				style: :double,
				ending: :arrow
			},

			description: "Shot."
		},

		pick: {
			id: 14,

			category: :action,
			group: :movement,

			editor: {
				action: :draw
			},

			path: {
				curve: true,
				style: :solid,
				ending: :tee
			},

			description: "Screen (pick)."
		},

		handoff: {
			id: 15,

			category: :action,
			group: :ball,

			editor: {
				action: :draw
			},

			path: {
				curve: false,
				style: :double,
				ending: :none
			},

			description: "Hand-off."
		}

	}.freeze
end
