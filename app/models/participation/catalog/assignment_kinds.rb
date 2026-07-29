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
# Catalog::AssignmentKinds
#
# Defines the canonical assigments recognised by MudClub.
#
# Assingments describe the function a member performs within either a Club
# or a Team. They are shared across the application and referenced by
# Assignment records, which allow each Club to enable the assignment kinds it
# wishes to use.
#
# Additional metadata classifies each AssingmentKind according to the module
# owning it and the scope in which it may be assigned.
#
class Catalog::AssignmentKinds < Catalog::Base
	domain "participation"

	CATALOG = {

		#
		# Athletes
		#

		athlete: {
			id: 0,
			membership_kind: :athlete,
			scope: :team,
			description: "Regular member of a team."
		},

		captain: {
			id: 10,
			membership_kind: :athlete,
			scope: :team,
			description: "Captain of a team."
		},

		#
		# Coaching
		#

		head_coach: {
			id: 20,
			membership_kind: :coach,
			scope: :team,
			description: "Head coach of a team."
		},

		assistant_coach: {
			id: 21,
			membership_kind: :coach,
			scope: :team,
			description: "Assistant coach of a team."
		},

		coaching_coordinator: {
			id: 22,
			membership_kind: :coach,
			scope: :club,
			description: "Coordinates the club's sporting methodology and supervises team coaches."
		},

		#
		# Volunteers
		#

		team_manager: {
			id: 30,
			membership_kind: [ :volunteer, :board_member ],
			scope: :team,
			description: "Administrative manager of a team."
		},

		team_delegate: {
			id: 31,
			membership_kind: :volunteer,
			scope: :team,
			description: "Represents the team before competition organisers and officials."
		},

		home_delegate: {
			id: 32,
			membership_kind: :volunteer,
			scope: :team,
			description: "Coordinates the organisation of home fixtures and assists match officials."
		},

		photographer: {
			id: 33,
			membership_kind: [ :volunteer, :board_member ],
			scope: :club,
			description: "Club photographer."
		},

		community_manager: {
			id: 34,
			membership_kind: :volunteer,
			scope: :club,
			description: "Handle social media interaction."
		},

		webmaster: {
			id: 35,
			membership_kind: :volunteer,
			scope: :club,
			description: "Manage club website."
		},

		club_manager: {
			id: 36,
			membership_kind: :club_manager,
			scope: :club,
			description: "Club operational manager."
		},

		#
		# Board
		#

		president: {
			id: 40,
			membership_kind: :board_member,
			scope: :club,
			description: "President of the club."
		},

		vice_president: {
			id: 41,
			membership_kind: :board_member,
			scope: :club,
			description: "Vice-president of the club."
		},

		secretary: {
			id: 42,
			membership_kind: :board_member,
			scope: :club,
			description: "Secretary of the club."
		},

		treasurer: {
			id: 43,
			membership_kind: :board_member,
			scope: :club,
			description: "Treasurer of the club."
		}

	}.freeze
end
