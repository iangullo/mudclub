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
# Catalog::RegistrationAuthorKinds
#
class Catalog::RegistrationAuthorKinds < Catalog::Base
	domain "admissions"

	CATALOG = {

		requester: {
			id: 1,
			can_edit_after_submission: true,
			candidate_relationship_required: true
		},

		reviewer: {
			id: 10,
			can_edit_after_submission: true,
			candidate_relationship_required: false
		},

		admin: {
			id: 20,
			can_edit_after_submission: true,
			candidate_relationship_required: false
		},

		system: {
			id: 30,
			can_edit_after_submission: true,
			candidate_relationship_required: false
		}

	}.freeze
end
