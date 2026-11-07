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
# Catalog::RegistrationActions
#
class Catalog::RegistrationActions < Catalog::Base
	domain "admissions"

	CATALOG = {

		save_draft: {
			id: 1,
			requester_allowed: true,
			reviewer_allowed: false,
			requires_comment: false,
			changes_status: :draft
		},

		submit: {
			id: 10,
			requester_allowed: true,
			reviewer_allowed: false,
			requires_comment: false,
			changes_status: :submitted
		},

		request_information: {
			id: 20,
			requester_allowed: false,
			reviewer_allowed: true,
			requires_comment: true,
			changes_status: :awaiting_requester,
			requester_can_edit: true
		},

		resume_review: {
			id: 30,
			requester_allowed: false,
			reviewer_allowed: true,
			requires_comment: false,
			changes_status: :under_review
		},

		approve: {
			id: 40,
			requester_allowed: false,
			reviewer_allowed: true,
			requires_comment: false,
			changes_status: :approved
		},

		reject: {
			id: 50,
			requester_allowed: false,
			reviewer_allowed: true,
			requires_comment: true,
			changes_status: :rejected
		},

		cancel: {
			id: 60,
			requester_allowed: true,
			reviewer_allowed: true,
			requires_comment: false,
			changes_status: :cancelled
		},

		archive: {
			id: 70,
			requester_allowed: false,
			reviewer_allowed: true,
			requires_comment: false,
			changes_status: :archived
		}

	}.freeze
end
