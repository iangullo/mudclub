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
class Person < ApplicationRecord
	localized_as "people.person"

	include PersonDataManagement
	include PgSearch::Model
	before_destroy :unlink
	before_save { self.name = self.name ? self.name.mb_chars.titleize : "" }
	before_save { self.surname = self.surname ? self.surname.mb_chars.titleize : "" }
	belongs_to :coach, optional: true	# DEPRECATED
	belongs_to :player, optional: true	# DEPRECATED
	belongs_to :user, optional: true	# DEPRECATED
	belongs_to :parent, optional: true	# DEPRECATED
	accepts_nested_attributes_for :coach	# DEPRECATED
	accepts_nested_attributes_for :player	# DEPRECATED
	accepts_nested_attributes_for :user
	has_many :memberships
	has_many :relationships,
					class_name: "Relationship",
					dependent: :destroy
	accepts_nested_attributes_for :relationships, allow_destroy: true

	has_many :inverse_relationships,
					class_name: "Relationship",
					foreign_key: :related_person_id,
					dependent: :destroy
	has_one_attached :avatar
	has_one_attached :id_front
	has_one_attached :id_back
	pg_search_scope :search,
		against: [ :nick, :name, :surname ],
		ignoring: :accents,
		using: { tsearch: { prefix: true } }
	scope :real, -> { where("id>0") }
	scope :lost, -> {	where("(player_id=0) and (coach_id=0) and (user_id=0) and (parent_id=0)") }
	validates :email, uniqueness: { allow_nil: true }
	validates :dni, uniqueness: { allow_nil: true }
	validates :phone, uniqueness: { allow_nil: true }
	validates :name, :surname, presence: true
	self.inheritance_column = "not_sti"

	# calculate age
	def age
		if self.birthday
			now = Time.now.utc.to_date
			bday=self.birthday
			now.year - bday.year - ((now.month > bday.month || (now.month == bday.month && now.day >= bday.day)) ? 0 : 1)
		else
			0
		end
	end

	# returns a hash of icon & label to mark whether a
	# Person has attached id pictures (front && back)
	def idpic_content
		label = self.dni
		symbol = { concept: "id_front", options: { title: I18n.t("person.pid") } }
		if self.idpics_attached?
			found  = true
		else
			found  = self.id_front.attached? || self.id_back.attached?
			symbol[:options][:title]  += " (#{I18n.t("person.pics_missing")})"
			symbol[:options][:variant] = "none"
		end
		{ found:, symbol:, label: }
	end

	# checks whether a Person has attached id pictures (front && back)
	def idpics_attached?
		self.id_front.attached? && self.id_back.attached?
	end

	# used for clublogo (Person(id: 0)) - DEPRECATED
	def logo
		self.avatar.attached? ? self.avatar : "mudclub.svg"
	end

	def minor?
		self.age < 18
	end

	# extended modified to acount for changed parents or avatar
	def modified?
		self.changed? ||
			avatar.attachment_changes.present? ||
			id_front.attachment_changes.present? ||
			id_back.attachment_changes.present? ||
			relationships.any?(&:modified?)
	end

	# DEPRECATED
	# return if person is orphaned from any dependent objects
	def orphan?
		self&.id.to_i > 0 && (self.player_id.nil?) && (self.coach_id.nil?) && (self.user_id.nil?) && (self.parent_id.nil?)
	end

	# hopefully return self...
	def person
		self
	end

	# personal logo
	def picture
		self.avatar.attached? ? self.avatar : "person.svg"
	end

	# rebuild Person data from raw input (as hash) given by a form submittal
	def rebuild(data)
		self.dni       = data[:dni].presence			|| self.dni
		self.email     = data[:email].presence		|| self.email
		self.name      = data[:name].presence 		|| self.name
		self.surname   = data[:surname].presence 	|| self.surname
		self.address   = data[:address].presence 	|| self.address
		self.birthday  = data[:birthday].presence || self.birthday
		self.nick      = data[:nick].presence 		|| self.nick

		self.female    = to_boolean(data[:female])
		self.phone     = parse_phone(data[:phone]) 					if data[:phone].presence
		self.update_attachment("avatar", data[:avatar])			if data[:avatar].present?
		self.update_attachment("id_front", data[:id_front]) if data[:id_front].present?
		self.update_attachment("id_back", data[:id_back]) 	if data[:id_back].present?

		# DEPRECATED - REMOVE ONCE MEMBERSHIPS are complete
		self.coach_id  = nil unless self.coach_id.to_i > 0
		self.player_id = nil unless self.player_id.to_i > 0
		self.parent_id = nil unless self.parent_id.to_i > 0
		self.user_id   = nil unless self.user_id.to_i > 0

		rebuild_relationships(data[:relationships_attributes]) if data[:relationships_attributes]

		self
	end

	# Return list of responsible adults related to this person
	def responsible_adults
		relationships.active.where(
			kind: %i[parent father mother guardian legal_representative]
		)
	end

	# short name for form viewing
	def s_name
		res = "#{self.to_s(false)} #{self.surname&.split&.first}"
		res.present? ? res : I18n.t("person.single")
	end

	def to_s(long = true)
		aux = self.nick.presence || self.name.to_s
		aux += " #{self.surname}" if long
		aux
	end

	# finds a person in the database based on id, email, dni, name & surname
	# returns: reloads person if it exists in the database already or
	# 	   a freshly created person(id: nil) if it not found.
	def self.fetch(data)
		person = resolve(data)
		person.rebuild(data)
		person
	end

	# to import from excel
	def self.import(file)
		xlsx = Roo::Excelx.new(file.tempfile)
		xlsx.each_row_streaming(offset: 1, pad_cells: true) do |row|
			if row.empty?	# stop parsing if row is empty
				return
			else
				p = Person.fetch({ name: row[2].value, surname: row[3].value })
				if p.nil?
					p = self.new(
						name:      row[2].value.to_s.strip,
						surname:   row[3].value.to_s.strip,
						coach_id:  0,
						parent_id: 0,
						player_id: 0,
						user_id:   0
					)
				end
				p.import_person_row(
					[
						row[0], # dni
						row[2], # name
						row[3], # surname
						row[1],	# nick
						row[4],	# birthday
						row[6],	# address
						row[7],	# email
						row[8], # phone
						row[5]	# female
					]
				)
				p&.save
			end
		end
	end

	#
	# Resolve a person from a set of identifying attributes.
	#
	# Returns a hash with:
	#   :person => existing or new Person
	#   :status => :exact, :probable, :new, :ambiguous
	#
	def self.resolve(data)
		data ||= {}

		#
		# 1. Explicit id
		#
		if data[:id].present?
			person = Person.find_by(id: data[:id])

			return { person:, status: :exact } if person
		end

		#
		# 2. Strong unique identifiers
		#
		if data[:dni].present?
			people = Person.where(dni: data[:dni])

			return resolve_candidates(people)
		end

		if data[:email].present?
			people = Person.where(email: data[:email])

			return resolve_candidates(people)
		end

		if data[:phone].present?
			phone = parse_phone(data[:phone])
			people = Person.where(phone:)

			return resolve_candidates(people)
		end

		#
		# 3. Name + surname (weak match)
		#
		if data[:name].present? && data[:surname].present?
			people = Person.where(
				"unaccent(name) ILIKE unaccent(?) AND unaccent(surname) ILIKE unaccent(?)",
				data[:name],
				data[:surname]
			)

			return resolve_candidates(people, probable: true)
		end

		#
		# 4. Nothing useful
		#
		{
			person: Person.new,
			status: :new
		}
	end

	private
		# called by unlink using either :coach, :player or :user as arguments
		def gen_unlink(kind)
			if (dep = self.send(kind.to_sym))
				self.update!("#{kind}_id".to_sym nil)
				dep.destroy
			end
		end

		def rebuild_relationships(data)
			data.each_value do |attrs|
				relationship =
					if attrs[:id].present?
						relationships.find(attrs[:id])
					else
						relationships.build
					end

				if ActiveModel::Type::Boolean.new.cast(attrs[:_destroy])
					relationship.mark_for_destruction
					next
				end

				relationship.rebuild(self, attrs)
			end
		end

		# unlink/delete dependent objects
		def unlink
			self.avatar.purge if self.try(:avatar)&.attached?
			gen_unlink(:coach) if self.coach_id.to_i > 0	# avoid deleting placeholders
			gen_unlink(:player) if self.player_id.to_i > 0
			gen_unlink(:user) if self.user_id
			gen_unlink(:parent) if self.parent_id
			UserAction.prune("/people/#{self.id}")
		end

		def self.resolve_candidates(scope, probable: false)
			case scope.count
			when 0
				{ person: Person.new, status: :new }

			when 1
				{ person: scope.first, status: probable ? :probable : :exact }

			else
				{ person: nil, status: :ambiguous }
			end
		end
end
