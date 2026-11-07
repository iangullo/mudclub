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
			groups: [ :parent, :responsible_adult ],
			description: "Parent of another person."
		},

		father: {
			id: 1,
			inverse: :child,
			selectable: true,
			groups: [ :parent, :responsible_adult ],
			description: "Father of another person."
		},

		mother: {
			id: 2,
			inverse: :child,
			selectable: true,
			groups: [ :parent, :responsible_adult ],
			description: "Mother of another person."
		},

		guardian: {
			id: 10,
			inverse: :ward,
			selectable: true,
			groups: [ :guardian, :responsible_adult ],
			description: "Legal or designated guardian."
		},

		ward: {
			id: 31,
			inverse: :guardian,
			groups: [],
			description: "Person under guardianship."
		},

		legal_representative: {
			id: 11,
			inverse: :represented_person,
			groups: [ :guardian, :responsible_adult ],
			description: "Legal representative."
		},

		represented_person: {
			id: 32,
			inverse: :legal_representative,
			groups: [],
			description: "Person represented legally."
		},

		#
		# Family
		#

		child: {
			id: 20,
			selectable: false,
			inverse: :parent,
			groups: [],
			description: "Child."
		},

		sibling: {
			id: 21,
			inverse: :sibling,
			selectable: false,
			groups: [],
			description: "Sibling."
		},

		grandparent: {
			id: 22,
			inverse: :grandchild,
			selectable: true,
			groups: [ :responsible_adult ],
			description: "Grandparent."
		},

		grandchild: {
			id: 23,
			selectable: true,
			inverse: :grandparent,
			groups: [],
			description: "Grandchild."
		},

		spouse: {
			id: 24,
			inverse: :spouse,
			groups: [],
			description: "Spouse."
		},

		partner: {
			id: 25,
			inverse: :partner,
			groups: [],
			description: "Partner."
		},

		#
		# Contacts
		#

		emergency_contact: {
			id: 30,
			inverse: :emergency_contact_for,
			groups: [],
			description: "Emergency contact."
		},

		emergency_contact_for: {
			id: 33,
			inverse: :emergency_contact,
			groups: [],
			description: "Person for whom this is the emergency contact."
		}
	}.freeze

	def self.inverse_of(key)
		data = self[key]
		data ? data[:inverse] : nil
	end

	def self.selectable?(kind)
		CATALOG[kind.to_sym][:selectable] == true
	end

	def self.normalize(value)
		super(value)&.to_s&.singularize&.to_sym
	end

	# Available groups in the catalog
	def self.groups
		CATALOG.values.flat_map { |data| Array(data[:groups]) }.uniq
	end

	# All groups this kind belongs to
	def self.groups_of(kind)
		Array(self[kind]&.dig(:groups))
	end

	# Is this kind part of the given group?
	def self.in_group?(kind, group)
		groups_of(kind).include?(group)
	end

	# All kinds tagged with this group
	def self.with_group(group)
		CATALOG.select { |_kind, data| Array(data[:groups]).include?(group) }.keys
	end
end
