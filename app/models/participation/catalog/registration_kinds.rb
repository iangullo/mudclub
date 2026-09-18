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
# Catalog::RegistrationKinds
#
class Catalog::RegistrationKinds < Catalog::Base
	domain "participation"

	CATALOG = {

		athlete: {
			id: 1,
			membership_kind: :athlete,
			selectable: true,
			team_required: true,
			creates_assignment: true,
			required_documents: %i[
				photo
				id_front
				id_back
				medical_certificate
				insurance
				payment_details
				parental_authorization
			],
			accepted_documents: %i[ athlete_terms privacy_policy ],
			requester_allowed: %i[ self parent guardian ]
		},

		coach: {
			id: 10,
			membership_kind: :coach,
			selectable: true,
			team_required: false,
			creates_assignment: false,
			required_documents: %i[
				photo
				id_front
				id_back
				coaching_certificate
				medical_certificate
			],
			accepted_documents: %i[ coach_contract privacy_policy ],
			requester_allowed: %i[ self club_manager ]
		},

		volunteer: {
			id: 20,
			membership_kind: :volunteer,
			selectable: true,
			team_required: false,
			required_documents: %i[ photo id_front id_back ],
			accepted_documents: %i[ privacy_policy ],
			requester_allowed: %i[ self club_manager ]
		},

		board_member: {
			id: 30,
			membership_kind: :board_member,
			team_required: false,
			required_documents: %i[ photo id_front id_back ],
			accepted_documents: %i[ privacy_policy ],
			requester_allowed: %i[ board_member ]
		},

		club_manager: {
			id: 40,
			membership_kind: :volunteer,
			team_required: false,
			required_documents: %i[ photo id_front id_back ],
			accepted_documents: %i[ privacy_policy ],
			requester_allowed: %i[ board_member ]
		},

		user: {
			id: 50,
			membership_kind: :volunteer,
			selectable: true,
			team_required: false,
			required_documents: %i[ photo id_front id_back ],
			accepted_documents: %i[ privacy_policy ],
			requester_allowed: %i[ self admin club_manager ]
		}

	}.freeze

	def self.normalize(value)
		super(value)&.to_s&.singularize&.to_sym
	end
end
