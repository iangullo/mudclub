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
# Catalog::Modules
#
# Defines the canonical application modules recognised by MudClub.
#
# Each module represents a functional domain within the application.
#
# Additional metadata describes module dependencies and installation
# characteristics.
#
class Catalog::Modules < Catalog::Base
	CATALOG = {

		core: {
			id: 0,
			dependencies: [],
			optional: false,
			description:
				"Shared infrastructure and foundational services used throughout MudClub."
		},

		calendar: {
			id: 10,
			dependencies: [ :core ],
			optional: false,
			description:
				"Scheduling infrastructure shared by business modules."
		},

		people: {
			id: 20,
			dependencies: [ :core ],
			optional: false,
			description:
				"People, relationships and personal information."
		},

		organization: {
			id: 30,
			dependencies: [ :core ],
			optional: false,
			description:
				"Clubs, divisions, categories and organisational entities."
		},

		participation: {
			id: 40,
			dependencies: [ :core, :people, :organization ],
			optional: false,
			description:
				"Membership, assignments and organisational participation within clubs."
		},

		training: {
			id: 50,
			dependencies: [ :core, :participation, :calendar ],
			optional: true,
			description:
				"Training sessions, drills, tasks, objectives and player development."
		},

		competition: {
			id: 60,
			dependencies: [ :core, :participation, :calendar, :training ],
			optional: true,
			description:
				"Fixtures, competitions, standings and sporting results."
		},

		communication: {
			id: 70,
			dependencies: [ :core ],
			optional: true,
			description:
				"Internal and external communications including messaging, notifications and public communications."
		},

		finance: {
			id: 80,
			dependencies: [ :core, :organization, :participation ],
			optional: true,
			description:
				"Fees, invoicing, payments and financial administration."
		}

	}.freeze
end
