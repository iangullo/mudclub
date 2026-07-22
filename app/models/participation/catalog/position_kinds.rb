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
# Catalog::PositionKinds
#
# Defines the canonical positions recognised by MudClub.
#
# Positions describe the function a member performs within either a Club
# or a Team. They are shared across the application and referenced by
# Position records, which allow each Club to enable the positions it
# wishes to use.
#
# Additional metadata classifies each position according to the module
# owning it and the scope in which it may be assigned.
#
class Catalog::PositionKinds < Catalog::Base
	CATALOG = {

		#
		# Athletes
		#

		athlete: {
			id: 0,
			required_membership: :athlete,
			scope: :team,
			description: "Regular member of a team."
		},

		captain: {
			id: 10,
			required_membership: :athlete,
			scope: :team,
			description: "Captain of a team."
		},

		#
		# Coaching
		#

		head_coach: {
			id: 20,
			required_membership: :coach,
			scope: :team,
			description: "Head coach of a team."
		},

		assistant_coach: {
			id: 21,
			required_membership: :coach,
			scope: :team,
			description: "Assistant coach of a team."
		},

		coaching_coordinator: {
			id: 22,
			required_membership: :coach,
			scope: :club,
			description: "Coordinates the club's sporting methodology and supervises team coaches."
		},

		#
		# Volunteers
		#

		team_manager: {
			id: 30,
			required_membership: [ :volunteer, :board_member ],
			scope: :team,
			description: "Administrative manager of a team."
		},

		team_delegate: {
			id: 31,
			required_membership: :volunteer,
			scope: :team,
			description: "Represents the team before competition organisers and officials."
		},

		home_delegate: {
			id: 32,
			required_membership: :volunteer,
			scope: :team,
			description: "Coordinates the organisation of home fixtures and assists match officials."
		},

		photographer: {
			id: 33,
			required_membership: [ :volunteer, :board_member ],
			scope: :club,
			description: "Club photographer."
		},

		community_manager: {
			id: 34,
			required_membership: :volunteer,
			scope: :club,
			description: "Handle social media interaction."
		},

		webmaster: {
			id: 35,
			required_membership: :volunteer,
			scope: :club,
			description: "Manage club website."
		},

		club_manager: {
			id: 36,
			required_membership: :club_manager,
			scope: :club,
			description: "Club operational manager."
		},

		#
		# Board
		#

		president: {
			id: 40,
			required_membership: :board_member,
			scope: :club,
			description: "President of the club."
		},

		vice_president: {
			id: 41,
			required_membership: :board_member,
			scope: :club,
			description: "Vice-president of the club."
		},

		secretary: {
			id: 42,
			required_membership: :board_member,
			scope: :club,
			description: "Secretary of the club."
		},

		treasurer: {
			id: 43,
			required_membership: :board_member,
			scope: :club,
			description: "Treasurer of the club."
		}

	}.freeze
end
