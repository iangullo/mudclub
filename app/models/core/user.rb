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
class User < ApplicationRecord
	localized_as("core.user")
	include PersonBearing

	before_destroy :unlink

	# -------------------------------------------------------------------------
	# Object associations
	# -------------------------------------------------------------------------
	# Include default devise modules. Others available are:
	# :confirmable, :lockable, :timeoutable, :registerable and :omniauthable
	devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable
	belongs_to :club, optional: true
	belongs_to :person
	accepts_nested_attributes_for :person

	has_one_attached :avatar
	has_many :user_actions, dependent: :destroy

	# -------------------------------------------------------------------------
	# Scopes & definitions
	# -------------------------------------------------------------------------
	scope :real, -> { where("id>0") }
	enum :role, %i[user player coach manager admin secretary], default: :user

	self.inheritance_column = "not_sti"

	# ---------------------------------------------------------------------------
	# System-level predicates (2.x)
	# ---------------------------------------------------------------------------
	def system_admin?
		admin?
	end

	def system_role
		admin? ? :admin : :user
	end

	def active?
		system_admin? || person&.memberships&.current&.any?
	end

	# ---------------------------------------------------------------------------
	# Organizational roles — delegate to Person, which derives from Participation
	# ---------------------------------------------------------------------------
	delegate :is_athlete?, :is_coach?, :is_secretary?, :is_president?,
					:clubs, :club_list, :teams, :team_list,
					to: :person, allow_nil: true

	# -------------------------------------------------------------------------
	# User Predicates
	# TODO: Re-design to manage club-less athletes/coaches
	# -------------------------------------------------------------------------
	def coach
		return nil unless club
		person.memberships
					.current
					.for_club(club)
					.of_kind(:coach)
					.first
	end

	def is_manager?
		person.is_manager? || (admin? && is_coach?)
	end

	def athlete
		return nil unless club
		person.memberships
					.current
					.for_club(club)
					.of_kind(:athlete)
					.first
	end
	alias player athlete

	# return last login IP
	def last_from
		self.last_sign_in_ip
	end

	# return string with last date of user login
	def last_login
		res = self.last_sign_in_at&.to_date
		res ? res : I18n.t("user.never")
	end

	# wrappers for locale setting
	def locale
		settings[:locale]
	end

	def locale=(newlocale)
		set_setting(:locale, newlocale)
	end

	# return attached avatar (or default user icon)
	def picture
		self.avatar.attached? ? self.avatar : "user.svg"
	end

	# rebuild User data from raw input hash given by a form submittal
	# avoids duplicate person binding
	def rebuild(f_data)
		f_data[:person_attributes][:email] ||= f_data[:email]
		return self unless resolve_person(f_data[:person_attributes])

		self.club_id  = f_data[:club_id].presence
		self.email    = self.person.email
		self.role     = f_data[:role] || :user
		self.locale   = f_data[:locale] if f_data[:locale]
		self.password = f_data[:password] if f_data[:password]
		self.password_confirmation = f_data[:password_confirmation] if f_data[:password_confirmation]
		self.update_attachment("avatar", f_data[:person_attributes][:avatar])
	end

	# short name for form viewing
	def s_name
		if self.person
			self.person.nick.presence || self.person.s_name
		else
			User.label
		end
	end

	# Getter method for accessing the settings hash
	def settings
		super&.symbolize_keys || {}
	end

	# Setter method for updating the settings hash
	def settings=(value)
		super(value&.to_h)
	end

	# Just list person's full name
	def to_s
		self.person&.to_s || I18n.t("user.single")
	end

	# atempt to fetch a User using form input hash
	def self.fetch(f_data)
		self.new.fetch_obj(f_data)
	end

	# list of possible user locales for select box configuration
	def self.locale_list
		I18n.available_locales.map do |locale|
			[ I18n.t("locale.#{locale}", locale:), locale ]
		end
	end

	# list of possible user roles for select box configuration
	def self.role_list
		User.roles.keys.map do |role|
			[ I18n.t("role.#{role}"), role ]
		end
	end

	# Search field matching
	def self.search(search, user = nil)
		if user.admin?
			if search.present?
				User.where(person_id: Person.search(search))
			else
				User.real
			end
		else
			User.none
		end
	end

	# ---------------------------------------------------------------------------
	# Deprecated enum predicates
	#
	# These still reflect the stored column value (a legacy user with role=2
	# returns true for #coach?), but they no longer represent a system-level
	# concept. Callers must migrate to Participation queries.
	# ---------------------------------------------------------------------------

	private
		# generic setting method to be used for all setters
		def set_setting(key, value)
			self.settings = settings.merge(key => value)
		end

		# unlink dependent person
		def unlink
			UserAction.prune("/users/#{id}")
		end
end
