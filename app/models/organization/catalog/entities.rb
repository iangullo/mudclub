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
# Catalog::Entities
#
# Defines the canonical entities recognised by MudClub.
#
class Catalog::Entities < Catalog::Base
	CATALOG = {

		club: {
			id: 10,
			namespace: :core,
			scope: :global,
			lifecycle: :immutable,
			description:
				"Sports organisation managed by MudClub."
		},

		person: {
			id: 20,
			namespace: :core,
			scope: :club,
			lifecycle: :anonymisable,
			description:
				"Individual registered within a club."
		},

		user: {
			id: 30,
			namespace: :core,
			scope: :global,
			lifecycle: :archivable,
			description:
				"Authentication account used to access MudClub."
		},

		role: {
			id: 40,
			namespace: :core,
			scope: :club,
			lifecycle: :archivable,
			description:
				"Operational responsibility defined by a club."
		},

		sport: {
			id: 50,
			namespace: :core,
			scope: :club,
			lifecycle: :immutable,
			description:
				"Sport practised by a club."
		},

		season: {
			id: 60,
			namespace: :core,
			scope: :club,
			lifecycle: :archivable,
			description:
				"Time period grouping sporting activities."
		},

		team: {
			id: 70,
			namespace: :competition,
			scope: :club,
			lifecycle: :archivable,
			description:
				"Sporting team participating in activities or competitions."
		},

		membership: {
			id: 80,
			namespace: :participation,
			scope: :club,
			lifecycle: :archivable,
			description:
				"Relationship between a person and a club."
		},

		assignment: {
			id: 90,
			namespace: :participation,
			scope: :team,
			lifecycle: :archivable,
			description:
				"Operational responsibility exercised by a member."
		}

	}.freeze
end
