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

	include PgSearch::Model
	before_destroy :unlink
	before_save { self.name = self.name ? self.name.mb_chars.titleize : "" }
	before_save { self.surname = self.surname ? self.surname.mb_chars.titleize : "" }

	#-------------------------------------
	# Object relationships
	#-------------------------------------
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

	#-------------------------------------
	# Person Scopes
	#-------------------------------------
	pg_search_scope :search,
		against: [ :nick, :name, :surname ],
		ignoring: :accents,
		using: { tsearch: { prefix: true } }
	scope :real, -> { where("id>0") }
	scope :lost, -> {	where("(player_id=0) and (coach_id=0) and (user_id=0) and (parent_id=0)") }

	#-------------------------------------
	# Data validations
	#-------------------------------------
	validates :email, uniqueness: { allow_nil: true }
	validates :dni, uniqueness: { allow_nil: true }
	validates :phone, uniqueness: { allow_nil: true }
	validates :name, :surname, presence: true
	self.inheritance_column = "not_sti"

	#-------------------------------------
	# Indirect relationships API
	#-------------------------------------
	def clubs
		Club.joins(:memberships).merge(memberships.current).distinct
	end

	def club_list
		clubs.map { |c| [ c.nick, c.id ] }
	end

	def teams(club: nil, season: nil)
		scope = memberships.current
		scope = scope.for_club(club) if club

		assignment_ids = Assignment.where(membership_id: scope.select(:id))
												.current
												.where.not(team_id: nil)
												.select(:team_id)

		teams = Team.where(id: assignment_ids)
		teams = teams.where(season_id: season) if season
		teams.includes(:season).order("seasons.start_date DESC").distinct
	end

	def team_list(club: nil)
		teams(club:).includes(:season).sort_by { |t| t.season.start_date }.reverse
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

	def is_athlete?(club = nil) = has_membership?(:athlete, club)
	def is_coach?(club = nil)		= has_membership?(:coach, club)
	def is_manager?(club)				= has_assignment?(:club_manager, club)
	def is_president?(club)			= has_assignment?(:president, club)
	def is_secretary?(club)			= has_assignment?(:secretary, club)
	def is_treasurer?(club)			= has_assignment?(:treasurer, club)

	#-------------------------------------
	# Object methods
	#-------------------------------------
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

	def dependents
		Person.where(id: relationships.in_group(:responsible_adult).select(:related_person_id))
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

	# extended modified to check relationships
	def modified?
		super ||
			relationships.any?(&:modified?)
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
		return [ self ] if age>18
		relationships.where(
			kind: %i[parent father mother guardian legal_representative]
		)
	end

	def to_s(long = true)
		aux = self.nick.presence || self.name.to_s
		aux += " #{self.surname}" if long
		aux
	end

	# short name for form viewing
	def s_name
		res = "#{self.to_s(false)} #{self.surname&.split&.first}"
		res.present? ? res : I18n.t("person.single")
	end

	#
	# Resolve a Person from identifying attributes.
	#
	# Returns:
	#   {
	#     person:     Person | nil,
	#     status:     :exact | :probable | :new | :ambiguous,
	#     matched_by: Symbol | nil
	#   }
	#
	def self.resolve(data)
		data ||= {}

		#
		# 1. Explicit id
		#
		if data[:id].present?
			person = find_by(id: data[:id])
			return {
				person:,
				status: :exact,
				matched_by: :id
			} if person
		end

		#
		# 2. Strong identifiers
		#
		{
			dni:   data[:dni],
			email: data[:email],
			phone: data[:phone].present? ? parse_phone(data[:phone]) : nil
		}.each do |field, value|
			next if value.blank?

			result = resolve_candidates(
				where(field => value),
				matched_by: field
			)

			return result unless result[:status] == :new
		end

		#
		# 3. Weak identification
		#
		if data[:name].present? && data[:surname].present?
			result = resolve_candidates(
				search("#{data[:name]} #{data[:surname]}"),
				probable: true,
				matched_by: :name
			)

			return result unless result[:status] == :new
		end

		#
		# 4. Nothing matched
		#
		{
			person: Person.new,
			status: :new,
			matched_by: nil
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

		# called by unlink using either :coach, :player or :user as arguments
		# DEPRECATED
		def gen_unlink(kind)
			if (dep = self.send(kind.to_sym))
				self.update!("#{kind}_id".to_sym nil)
				dep.destroy
			end
		end

		def active_assignments(kind, club)
			return nil unless club
			assignments_in(club).find { |a| a.kind.to_sym == kind.to_sym }
		end

		def has_assignment?(kind, club)
			active_assignments(kind, club).exists?
		end

		def active_memberships(kind, club = nil)
			scope = memberships.of_kind(kind.to_sym).current
			club ? scope.for_club(club) : scope
		end

		def has_membership?(kind, club = nil)
			active_memberships(kind, club).exists?
		end

		def membership_of_kind_in(club, kind)
			return nil unless club
			memberships_in(club).find { |m| m.kind.to_sym == kind.to_sym }
		end

		def self.resolve_candidates(scope, probable: false, matched_by:)
			people = scope.to_a

			case people.size
			when 0
				{ person: Person.new, status: :new, matched_by: nil }

			when 1
				{ person: people.first, status: probable ? :probable : :exact, matched_by: }

			else
				{ person: nil, status: :ambiguous, matched_by: }
			end
		end
end
