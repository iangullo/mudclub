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
	CATALOG = {

		#
		# Parents
		#

		parent: {
			id: 0,
			description: "Parent of another person."
		},

		father: {
			id: 1,
			description: "Father of another person."
		},

		mother: {
			id: 2,
			description: "Mother of another person."
		},

		guardian: {
			id: 10,
			description: "Legal or designated guardian."
		},

		legal_representative: {
			id: 11,
			description: "Legal representative."
		},

		#
		# Family
		#

		child: {
			id: 20,
			description: "Child."
		},

		sibling: {
			id: 21,
			description: "Sibling."
		},

		grandparent: {
			id: 22,
			description: "Grandparent."
		},

		grandchild: {
			id: 23,
			description: "Grandchild."
		},

		spouse: {
			id: 24,
			description: "Spouse."
		},

		partner: {
			id: 25,
			description: "Partner."
		},

		#
		# Contacts
		#

		emergency_contact: {
			id: 30,
			description: "Emergency contact."
		}

	}.freeze
end
