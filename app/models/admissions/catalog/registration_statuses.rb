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
# Catalog::RegistrationStatuses
#
class Catalog::RegistrationStatuses < Catalog::Base
	domain "admissions"

	CATALOG = {

		draft: {
			id: 1,
			initial: true,
			editable_by_requester: true,
			transitions: %i[under_review]
		},

		under_review: {
			id: 10,
			review_open: true,
			editable_by_requester: false,
			transitions: %i[awaiting_requester approved rejected]
		},

		awaiting_requester: {
			id: 20,
			review_open: true,
			editable_by_requester: true,
			transitions: %i[under_review approved cancelled rejected]
		},

		cancelled: {
			id: 30,
			terminal: true,
			editable_by_requester: false,
			transitions: %i[]
		},

		approved: {
			id: 40,
			terminal: true,
			editable_by_requester: false,
			transitions: %i[]
		},

		rejected: {
			id: 50,
			terminal: true,
			editable_by_requester: false,
			transitions: %i[]
		}

	}.freeze
end
