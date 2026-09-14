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
# Catalog::DocumentKinds
#
# Defines the relevant documentation kinds
#
class Catalog::DocumentKinds < Catalog::Base
	domain "core"

	CATALOG = {

		# -------------------------------------------------------------------
		# Identity
		# -------------------------------------------------------------------

		photo: {
			id: 1,
			category: :identity,
			applies_to: %i[person registration],
			active_storage_name: :photo,
			file_type: :image,
			multiple: false
		},

		id_front: {
			id: 10,
			category: :identity,
			applies_to: %i[person registration],
			active_storage_name: :id_front,
			file_type: :image,
			multiple: false
		},

		id_back: {
			id: 20,
			category: :identity,
			applies_to: %i[person registration],
			active_storage_name: :id_back,
			file_type: :image,
			multiple: false
		},

		# -------------------------------------------------------------------
		# Medical
		# -------------------------------------------------------------------

		medical_certificate: {
			id: 30,
			category: :medical,
			applies_to: %i[person registration],
			file_type: :pdf,
			expires: 365.days,
			multiple: false
		},

		insurance: {
			id: 40,
			category: :medical,
			applies_to: %i[person registration],
			file_type: :pdf,
			multiple: false
		},

		# -------------------------------------------------------------------
		# Financial
		# -------------------------------------------------------------------

		payment_details: {
			id: 50,
			category: :financial,
			applies_to: %i[person registration],
			file_type: :pdf,
			multiple: false
		},

		# -------------------------------------------------------------------
		# Coaching
		# -------------------------------------------------------------------

		coaching_certificate: {
			id: 60,
			category: :coaching,
			applies_to: %i[person registration],
			file_type: :pdf,
			multiple: true
		},

		# -------------------------------------------------------------------
		# Legal / Club owned
		# -------------------------------------------------------------------

		athlete_terms: {
			id: 100,
			category: :legal,
			applies_to: %i[club],
			file_type: :pdf,
			versioned: true,
			requires_acceptance: true
		},

		coach_contract: {
			id: 110,
			category: :legal,
			applies_to: %i[club],
			file_type: :pdf,
			versioned: true,
			requires_acceptance: true
		},

		volunteer_agreement: {
			id: 120,
			category: :legal,
			applies_to: %i[club],
			file_type: :pdf,
			versioned: true,
			requires_acceptance: true
		},

		privacy_policy: {
			id: 130,
			category: :legal,
			applies_to: %i[club],
			file_type: :pdf,
			versioned: true,
			requires_acceptance: true
		},

		club_rules: {
			id: 140,
			category: :legal,
			applies_to: %i[club],
			file_type: :pdf,
			versioned: true,
			requires_acceptance: false
		},

		form: {
			id: 150,
			category: :legal,
			applies_to: %i[club registration],
			file_type: :pdf,
			active_storage_name: :form,
			multiple: false
		},


		# -------------------------------------------------------------------
		# Miscellaneous
		# -------------------------------------------------------------------

		parental_authorization: {
			id: 200,
			category: :legal,
			applies_to: %i[registration],
			file_type: :pdf,
			multiple: false
		},

		other: {
			id: 900,
			category: :other,
			file_type: :pdf,
			applies_to: %i[person registration club],
			multiple: true
		}

	}.freeze
end
