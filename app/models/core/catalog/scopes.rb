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
class Catalog::Scopes < Catalog::Base
	CATALOG = {

		none: {
			id: 0,
			parent: nil,
			description:
				"Not associated with any organisational scope."
		},

		global: {
			id: 1,
			parent: nil,
			description:
				"Applies to the entire MudClub installation."
		},

		club: {
			id: 10,
			parent: :global,
			description:
				"Applies to a specific club."
		},

		team: {
			id: 20,
			parent: :club,
			description:
				"Applies to a team within a club."
		}

	}.freeze
end
