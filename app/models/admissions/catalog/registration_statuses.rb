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
			requester_can_update: true,
			transitions: %i[submitted cancelled]
		},

		submitted: {
			id: 10,
			review_open: true,
			requester_can_update: false,
			transitions: %i[under_review cancelled]
		},

		under_review: {
			id: 20,
			review_open: true,
			requester_can_update: true,
			transitions: %i[awaiting_requester approved rejected]
		},

		awaiting_requester: {
			id: 30,
			review_open: true,
			requester_can_update: true,
			transitions: %i[under_review cancelled]
		},

		cancelled: {
			id: 40,
			terminal: true,
			requester_can_update: false,
			transitions: %i[archived]
		},

		approved: {
			id: 50,
			terminal: true,
			requester_can_update: false,
			transitions: %i[archived]
		},

		rejected: {
			id: 60,
			terminal: true,
			requester_can_update: false,
			transitions: %i[archived]
		}

	}.freeze
end
