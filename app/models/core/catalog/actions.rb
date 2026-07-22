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
# Catalog::Actions
#
# Defines the canonical actions that can be performed by MudClub.
#
# Actions are linked to entities & scopes.
#
class Catalog::Actions < Catalog::Base
	CATALOG = {

		view: {
			id: 10,
			description:
				"View information."
		},

		create: {
			id: 20,
			description:
				"Create new records."
		},

		update: {
			id: 30,
			description:
				"Modify existing records."
		},

		delete: {
			id: 40,
			description:
				"Delete records."
		},

		manage: {
			id: 50,
			description:
				"Full administrative control."
		},

		assign: {
			id: 60,
			description:
				"Assign people or resources."
		},

		approve: {
			id: 70,
			description:
				"Approve workflows or requests."
		},

		publish: {
			id: 80,
			description:
				"Publish information."
		},

		export: {
			id: 90,
			description:
				"Export data."
		}

	}.freeze
end
