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

	before_save { self.name    = self.name    ? self.name.mb_chars.titleize : "" }
	before_save { self.surname = self.surname ? self.surname.mb_chars.titleize : "" }
	after_commit :finalize_pending_merge

	UNIQUE_FIELDS = %i[dni email phone].freeze

	#-------------------------------------
	# Class relationships
	#-------------------------------------
	self.inheritance_column = "not_sti"
	belongs_to :user, optional: true
	accepts_nested_attributes_for :user
	has_many :memberships
	has_many :assignments, through: :memberships
	has_many :relationships,
					class_name: "Relationship",
					dependent: :destroy
	accepts_nested_attributes_for :relationships, allow_destroy: true

	has_many :inverse_relationships,
					class_name: "Relationship",
					foreign_key: :related_person_id,
					dependent: :destroy

	has_many :documents, dependent: :destroy
	accepts_nested_attributes_for :documents

	has_one_attached :avatar
	has_one_attached :id_front
	has_one_attached :id_back

	belongs_to :merged_into,	# Useful for conflict management
						class_name: "Person",
						optional: true

	has_many :merged_people,
					class_name: "Person",
					foreign_key: :merged_into_id,
					dependent: :nullify

	#-------------------------------------
	# Included Modules
	#-------------------------------------
	include PgSearch::Model
	include PersonData

	#-------------------------------------
	# Validations
	#-------------------------------------
	validate :cannot_merge_into_self
	validates :dni, uniqueness: { allow_nil: true }
	validates :email, uniqueness: { allow_nil: true }
	validates :name, :surname, presence: true
	validates :phone, uniqueness: { allow_nil: true }

	#-------------------------------------
	# Person Scopes
	#-------------------------------------
	scope :current, -> { real.where(merged_into_id: nil) }
	scope :lost, -> {	where("(player_id=0) and (coach_id=0) and (user_id=0) and (parent_id=0)") }
	scope :real, -> { where("id>0") }
	scope :placeholder, -> { where(id: 0) }
	pg_search_scope :search, against: [ :nick, :name, :surname ],
									ignoring: :accents, using: { tsearch: { prefix: true } }

	#-------------------------------------
	# Indirect relationships API
	#-------------------------------------
	def member_of?(club)		 = memberships.current.for_club(club).exists?
	def was_member_of?(club) = memberships.for_club(club).exists?

	def clubs
		Club.joins(:memberships).merge(memberships.current).distinct
	end

	def club_list
		clubs.map { |c| [ c.nick, c.id ] }
	end

	def teams(club: nil, season: nil, historical: false)
		scope = person.memberships
		scope = scope.current unless historical
		scope = scope.for_club(club) if club

		assig = Assignment.team_level.where(membership: scope)
		assig = assig.current unless historical

		t_ids = assig.select(:team_id)
		teams = Team.where(id: t_ids)
		teams = teams.where(season_id: season) if season
		teams.includes(:season).order("seasons.start_date DESC").distinct
	end

	def team_list(club: nil, season: nil, historical: false)
		teams(club:, season:, historical:).includes(:season).sort_by { |t| t.season.start_date }.reverse
	end

	# Person has guardians (i.e. is a minor with responsible adults)
	def has_guardians?
		inverse_relationships.in_group(:responsible_adult).exists?
	end

	# Person is a guardian of others (i.e. is someone's parent/legal representative)
	def is_responsible_adult?
		relationships.in_group(:responsible_adult).exists?
	end
	alias is_parent? is_responsible_adult?

	def has_membership?(kind, club = nil)
		active_memberships(Array(kind), club).exists?
	end

	def is_athlete?(club = nil)		= has_membership?(:athlete, club)
	def is_coach?(club = nil)			= has_membership?(:coach, club)
	def is_volunteer?(club = nil)	= has_membership?(:volunteer, club)
	def is_board_member?(club = nil) = has_membership?(:board_member, club)

	def has_assignment?(kind, club)
		active_assignments(Array(kind), club).exists?
	end

	def is_president?(club)				= has_assignment?(:president, club)
	def is_vice_president?(club)	= has_assignment?(:vice_president, club)
	def is_secretary?(club)				= has_assignment?(:secretary, club)
	def is_treasurer?(club)				= has_assignment?(:treasurer, club)
	def is_manager?(club)					= has_assignment?(:club_manager, club)

	#-------------------------------------
	# Object methods
	#-------------------------------------

	# absorb another duplicate person and mark it as merged
	def absorb!(duplicate)
		transaction do
			raise ArgumentError if duplicate == self

			merge_attributes_from(duplicate)
			merge_attachments_from(duplicate)
			merge_users_from(duplicate)
			merge_relationships_from(duplicate)
			merge_memberships_from(duplicate)

			@merged_person = duplicate
		end
	end

	# return the version of this person that is not marked
	# to be purged
	def canonical
		merged_into ? merged_into.canonical : self
	end

	def canonical?
		!placeholder? && !merged?
	end

	# check for duplicates in the database for unique data
	def conflicts
		conflicts = {}

		Person.unique_identifier_fields.each do |field|
			value = public_send(field)
			next if value.blank?

			scope = Person.current.where(field => value).where.not(id: id)

			conflicts[field] = scope.first if scope.exists?
		end

		conflicts
	end

	def dependents
		Person.where(id: relationships.in_group(:responsible_adult).select(:related_person_id))
	end

	# used for clublogo (Person(id: 0)) - DEPRECATED
	def logo
		self.avatar.attached? ? self.avatar : "mudclub.svg"
	end

	def merged?
		merged_into_id.present?
	end

	# extended modified to check relationships
	def modified?
		super ||
			relationships.any? { |r| r.modified? }
	end

	# return if person is orphaned from any dependent objects
	def orphan?
		self&.id.to_i > 0 && memberships.empty? &&
			player_id.nil? && coach_id.nil? && user_id.nil? && parent_id.nil? # DEPRECATED
	end

	# hopefully return self...
	def person
		self
	end

	def placeholder?
		id.zero?
	end

	# Return list of responsible adults related to this person
	def responsible_adults
		return [ self ] if age>18
		relationships.where(
			kind: %i[parent father mother guardian legal_representative]
		)
	end

	# Try to resolve a Person from identifying attributes.
	#
	# Returns:
	#   {
	#     person:     Person | nil,
	#     status:     :exact | :probable | :new | :ambiguous,
	#     matched_by: Symbol | nil
	#   }
	def self.resolve(data)
		data ||= {}

		# 1. Strong identifiers
		Person.unique_identifier_fields.each do |field|
			next if data[field].blank?

			value =
				case field
				when :phone then parse_phone(data[:phone])
				else data[field]
				end
			result = seek_candidates(
				current.where(field => value), matched_by: field
			)

			return result unless result.none?
		end

		# 2. Weak identification
		if data[:name].present? && data[:surname].present?
			result = seek_candidates(
				current.search("#{data[:name]} #{data[:surname]}"),
				probable: true,
				matched_by: :name
			)

			return result unless result.none?
		end

		# 3. Nothing matching found
		PersonResolution.new(status: :none)
	end

	private
		def active_memberships(kinds, club = nil)
			scope = memberships.of_kind(kinds).current
			club.is_a?(Club) ? scope.for_club(club) : scope
		end

		def active_assignments(kinds, obj = nil)
			scope = assignments.of_kind(kinds).current
			case obj
			when Club then scope.for_club(obj)
			when Team then scope.for_team(obj)
			else scope
			end
		end

		def cannot_merge_into_self
			errors.add(:merged_into, :invalid) if merged_into_id == id
		end

		def finalize_pending_merge
			return unless @merged_person

			@merged_person.update!(
				merged_into: self,
				nick: "[MERGED]",
				email: nil,
				phone: nil
			)

			@merged_person = nil
		end

		def merge_attachments_from(duplicate)
			%i[avatar id_front id_back].each do |attachment|
				merge_attachment(attachment, duplicate)
			end
		end

		def merge_attachment(name, duplicate)
			mine   = public_send(name)
			theirs = duplicate.public_send(name)

			return if mine.attached?
			return unless theirs.attached?

			mine.attach(theirs.blob)
		end

		def merge_attributes_from(duplicate)
			mergeable = %i[nick name surname birthday female dni email phone address]

				self.avatar.attach(duplicate.avatar.blob) if !avatar.attached? && duplicate.avatar.attached?
				mergeable.each do |field|
				current  = public_send(field)
				incoming = duplicate.public_send(field)

				next if incoming.blank?
				next if current.present?

				public_send("#{field}=", incoming)
				duplicate.public_send("#{field}=", nil) if UNIQUE_FIELDS.include?(field)
			end
		end

		def merge_memberships_from(duplicate)
			duplicate.memberships.find_each do |membership|
				existing = memberships.find_by(club_id: membership.club_id, kind: membership.kind)
				if existing
					existing.merge_from(membership)
					membership.destroy!
				else
					membership.update!(person: self)
				end
			end
		end

		def merge_users_from(duplicate)
			users = User.where(person: duplicate)
			users.each do |user|
				duplicate.update! user_id: nil
				user.update!(person: self)
			end
		end

		def merge_relationships_from(duplicate)
			duplicate.relationships.each do |relationship|
				existing = relationships.find_by(related_person_id: relationship.related_person_id)
				if relationship.kind == existing&.kind
					relationship.destroy!
				else
					relationship.update!(person: self)
				end
			end
		end

		def rebuild_relationships(r_data)
			return nil if r_data.blank?

			hash    = r_data.respond_to?(:to_unsafe_h) ? r_data.to_unsafe_h : r_data.to_h
			entries = hash.values
			return if entries.empty?

			Relationship.transaction do
				entries.each do |raw|
					attrs = raw.deep_symbolize_keys
					id    = attrs[:id].presence

					# Rails sends _destroy as "1" / "true" / "0" / "false" as strings.
					# Boolean cast normalizes all four.
					if ActiveModel::Type::Boolean.new.cast(attrs[:_destroy])
						relationships.where(id:).destroy_all if id.present?
						next
					end

					relationship = id.present? ? relationships.find_by(id:) : relationships.build
					relationship ||= relationships.build
					relationship.rebuild(self, attrs)
					relationship.errors.each do |error|
						errors.add(:"relationships.#{error.attribute}", error.message)
					end if relationship.invalid?
				end
			end
		end

		def self.seek_candidates(scope, probable: false, matched_by:)
			people = scope.to_a

			case people.size
			when 0
				PersonResolution.new(status: :none)

			when 1
				PersonResolution.new(status: probable ? :probable : :exact, person: people.first, matched_by:)

			else
				PersonResolution.new(status: :ambiguous, people:, matched_by:)
			end
		end

		def self.unique_identifier_fields(include_id: false)
			include_id ? %i[id dni email phone] : %i[dni email phone]
		end
end
