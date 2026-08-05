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

	validates :person, presence: true
	validates :related_person, presence: true
	validates :kind, presence: true

	validate :people_must_be_different
	validate :compatible_people

	validates :person_id,
						uniqueness: {
							scope: [ :related_person_id, :kind ]
						}
	validate :related_person_must_be_valid

	def kind_for(viewer = nil)
		viewer == related_person ? inverse_kind : kind.to_sym
	end

	def inverse_kind
		Catalog::RelationshipKinds.inverse_of(kind.to_sym)
	end

	def kind_label(...)
		self.class.kind_label(kind.to_sym, ...)
	end

	def normalize!
		return if kind.blank?
		return if Catalog::RelationshipKinds.selectable?(kind.to_sym)

		self.person, self.related_person = related_person, person
		self.kind = inverse_kind
	end

	def modified?
		self.changed?
	end

	def rebuild(person, data)
		self.person  = person
		self.kind    = data[:kind].to_sym if data.key?(:kind)
		related_data = data[:related_person_attributes] || {}

		result = Person.resolve(related_data)

		case result[:status]
		when :exact, :probable
			self.related_person = result[:person]

		when :new
			self.related_person = result[:person]

		when :ambiguous
			errors.add(:related_person, :ambiguous)
			return self
		end

		related_person.rebuild(related_data)
		normalize!

		self
	end

	def self.build_for(person, kind: :parent)
		new(person:, kind:).tap do |relationship|
			relationship.build_related_person
		end
	end

	def self.kind_label(kind, ...)
		self.val(kind.to_sym, ...)
	end

	def self.kind_list
		Catalog::RelationshipKinds.selectable.map do |kind|
			[ self.val(kind), kind ]
		end
	end

	private

	def people_must_be_different
		return unless person && related_person

		errors.add(:related_person, :same_person) if person == related_person
	end

	def compatible_people
		nil unless person && related_person
	end

	def related_person_must_be_valid
		return unless related_person

		unless related_person.valid?
			related_person.errors.each do |error|
				errors.add(:related_person, error.full_message)
			end
		end
	end
end
