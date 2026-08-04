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
# Catalog::RelationshipKinds
#
# Defines the recognised relationship kinds between two people.
#
# Relationships are independent from club membership and describe
# family, legal or social links between Person records.
#
# They may optionally carry additional metadata such as emergency
# contact, legal authority or notification preferences.
#
class Catalog::RelationshipKinds < Catalog::Base
	domain "people"

	CATALOG = {

		#
		# Parents
		#

		parent: {
			id: 0,
			inverse: :child,
			selectable: true,
			description: "Parent of another person."
		},

		father: {
			id: 1,
			inverse: :child,
			selectable: true,
			description: "Father of another person."
		},

		mother: {
			id: 2,
			inverse: :child,
			selectable: true,
			description: "Mother of another person."
		},

		guardian: {
			id: 10,
			inverse: :ward,
			selectable: true,
			description: "Legal or designated guardian."
		},

		ward: {
			id: 31,
			inverse: :guardian,
			description: "Person under guardianship."
		},

		legal_representative: {
			id: 11,
			inverse: :represented_person,
			description: "Legal representative."
		},

		represented_person: {
			id: 32,
			inverse: :legal_representative,
			description: "Person represented legally."
		},

		#
		# Family
		#

		child: {
			id: 20,
			inverse: :parent,
			description: "Child."
		},

		sibling: {
			id: 21,
			inverse: :sibling,
			description: "Sibling."
		},

		grandparent: {
			id: 22,
			inverse: :grandchild,
			selectable: true,
			description: "Grandparent."
		},

		grandchild: {
			id: 23,
			inverse: :grandparent,
			description: "Grandchild."
		},

		spouse: {
			id: 24,
			inverse: :spouse,
			description: "Spouse."
		},

		partner: {
			id: 25,
			inverse: :partner,
			description: "Partner."
		},

		#
		# Contacts
		#

		emergency_contact: {
			id: 30,
			inverse: :emergency_contact_for,
			selectable: true,
			description: "Emergency contact."
		},

		emergency_contact_for: {
			id: 33,
			inverse: :emergency_contact,
			description: "Person for whom this is the emergency contact."
		}
	}.freeze
end
