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
class Relationship < ApplicationRecord
	localized_as "people.relationship"
	self.table_name = "person_relationships"

	belongs_to :person
	belongs_to :related_person, class_name: "Person"
	accepts_nested_attributes_for :related_person

	enum :kind, Catalog::RelationshipKinds.enum

	scope :active, -> { where(ends_on: nil) }

	validates :person_id,
						uniqueness: {
							scope: [ :related_person_id, :kind ],
							conditions: -> { where(ends_on: nil) }
						}
	def to_s
		related_person.to_s
	end

	def inverse_kind
		Catalog::RelationshipKinds[self.kind][:inverse]
	end

	def kind_label(...)
		Catalog::RelationshipKinds.val(kind.to_sym, ...)
	end

	def self.build_for(person, kind: :parent)
		relationship = new(person: person, kind: kind)
		relationship.build_related_person unless relationship.related_person

		relationship
	end

	def self.kind_list
		Catalog::RelationshipKinds.selectable.map do |kind|
			[ self.val(kind), kind ]
		end
	end

	def self.kind_label(kind, ...)
		self.val(kind.to_sym, ...)
	end
end
