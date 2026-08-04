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

	before_validation :default_kind
	validates :kind, presence: true

	def inverse
		Relationship.find_by(
			person: related_person,
			related_person: person
		)
	end

	def inverse_kind
		Catalog::RelationshipKinds.inverse_of(kind)
	end

	def kind_label(...)
		self.class.kind_label(kind, ...)
	end

	def rebuild(data)
		self.kind = data[:kind]

		person_data = data[:related_person_attributes] || {}

		if related_person.nil?
			self.related_person =
				Person.search(person_data) ||
				Person.new
		end

		related_person.rebuild(person_data)

		self
	end

	def remove_inverse!
		inverse&.destroy
	end

	def sync_inverse!
		return unless person&.persisted?
		return unless related_person&.persisted?

		inverse_person = Relationship.find_or_initialize_by(
			person: related_person,
			related_person: person
		)

		inverse_person.kind      = inverse_kind
		inverse_person.save!
	end

	def self.kind_label(kind, ...)
		self.val(kind.to_sym, ...)
	end

	def self.kind_list
		Catalog::RelationshipKinds.selectable.map do |kind|
			[ self.val(kind), kind ]
		end
	end

	def self.build_for(person, kind: :parent)
		relationship = new(person: person, kind: kind)
		relationship.build_related_person

		relationship
	end
end
