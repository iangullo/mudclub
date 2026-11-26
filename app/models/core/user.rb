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
	before_destroy :unlink
	before_validation :normalize_email

	# -------------------------------------------------------------------------
	# Class relations
	# -------------------------------------------------------------------------
	self.inheritance_column = "not_sti"
	# Include default devise modules. Others available are:
	# :confirmable, :lockable, :timeoutable, :registerable and :omniauthable
	devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable
	belongs_to :club, optional: true

	has_one_attached :avatar
	has_many :user_actions, dependent: :destroy

	#-------------------------------------
	# Included Modules
	#-------------------------------------
	include HasSettings
	include PersonBearing

	# ---------------------------------------------------------------------------
	# Delegate to Person, which derives from Participation
	# ---------------------------------------------------------------------------
	delegate :was_member_of?, :clubs, :club_list, :teams, :team_list, :is_parent?,
		:memberships, :has_membership?, :is_athlete?, :is_coach?, :is_volunteer?, :is_board_member?,
		:assignments, :has_assignment?, :is_president?, :is_vice_president?, :is_treasurer?,
		:is_secretary?, :has_guardians?, # :is_manager? has local override
		:phone, :female,
		to: :person, allow_nil: true

	#-------------------------------------
	# Scopes
	#-------------------------------------
	scope :real, -> { where("id>0") }
	enum :role, %i[user player coach manager admin secretary], default: :user

	# ---------------------------------------------------------------------------
	# System-level predicates (2.x)
	# ---------------------------------------------------------------------------

	def active_for_authentication?	# Devise overrides
		super && anonymized_at.nil?
	end

	def anonymize!
		return if anonymized_at.present?

		if person&.canonical?
			person.anonymize!
		else
			anonymize_without_person!
		end
	end

	def anonymize_without_person!
		return if anonymized_at.present?

		if (att = ActiveStorage::Attachment.find_by(record_type: "User", record_id: id, name: "avatar"))
			blob = att.blob
			att.delete
			blob.purge unless ActiveStorage::Attachment.where(blob_id: blob.id).exists?
		end

		update_columns(
			person_id:            0,
			email:                "anonymized+#{SecureRandom.uuid}@invalid.local",
			encrypted_password:   SecureRandom.hex(32),
			reset_password_token: nil,
			remember_created_at:  nil,
			current_sign_in_ip:   nil,
			last_sign_in_ip:      nil,
			settings:             {},
			club_id:              nil,
			anonymized_at:        Time.current
		)
	end

	def inactive_message
		anonymized_at.present? ? :anonymized : super
	end

	# return club logo if it makes sense
	# Server logo otherwise
	def scope_logo
		u_club = memberships&.status_active&.first&.club
		u_club ? u_club.logo : Server.server_logo
	end

	def system_admin?
		admin?
	end

	def system_role
		admin? ? :admin : :user
	end

	def active?
		return false if respond_to?(:anonymized_at) && anonymized_at.present?
		system_admin? || person&.memberships&.current&.any?
	end

	def member_of?(club)
		person&.member_of?(club) || false
	end

	def is_manager?(club)
		person&.is_manager?(club) || (admin? && is_coach?(club))
	end

	# return last login IP
	def last_from
		self.last_sign_in_ip
	end

	# return string with last date of user login
	def last_login
		res = self.last_sign_in_at&.to_date
		res ? res : User.val(:never_logged)
	end

	# wrappers for locale setting
	def locale
		settings[:locale]
	end

	def locale=(newlocale)
		set_setting(:locale, newlocale)
	end

	# personal image
	def picture
		return avatar if avatar.attached?
		return person.picture if person&.canonical?

		{ symbol: :user }
	end

	# rebuild User data from raw input hash given by a form submittal
	# avoids duplicate person binding
	def rebuild(data)
		login_email = data[:email].to_s.strip.downcase.presence

		# Seed person_attributes[:email] from login_email if omitted so Person.resolve matches on email
		if login_email && data[:person_attributes].respond_to?(:[]=) && data[:person_attributes][:email].blank?
			data[:person_attributes][:email] = login_email
		end

		# --- associated person data ---
		resolution = prepare_person(data)
		return resolution unless resolution.ok?

		# --- actual user data ---
		self.club_id = data[:club_id].presence # DEPRECATED
		self.email   = login_email || resolution.person&.email || email
		self.role    = data[:role] || :user
		self.locale  = data[:locale] if data[:locale]

		if person&.canonical?
			person.email = email
			dbconflicts  = person.conflicts
			if dbconflicts.present?
				return PersonResolution.new(status: :conflict, person:, conflicts: dbconflicts)
			end
		end

		if data[:password].present?
			self.password              = data[:password]
			self.password_confirmation = data[:password_confirmation]
		end

		self.update_attachment("avatar", data[:avatar]) if data[:avatar].present?

		PersonResolution.new(status: :ok, person:)
	end

	# short name for form viewing
	def s_name
		if self.person
			self.person.nick.presence || self.person.s_name
		else
			User.label
		end
	end

	# Just list person's full name
	def to_s
		self.person&.to_s || User.label
	end

	# atempt to fetch a User using form input hash
	def self.fetch(f_data)
		self.new.fetch_obj(f_data)
	end

	# list of possible user locales for select box configuration
	def self.locale_list
		I18n.available_locales.map do |locale|
			[ UI::Locale.val(locale), locale ]
		end
	end

	# list of possible user roles for select box configuration
	# TODO: Review this in future with a catalog or move to use Kinded
	def self.role_list
		[
			[ I18n.t("core.user_kinds.values.user.single"), :user ],
			[ I18n.t("core.user_kinds.values.admin.single"), :admin ]
		]
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

	private
		# Users keep their own account avatar without overwriting their Person profile photo
		def avatar_propagation_target
			nil
		end

		def normalize_email
			self.email = email.to_s.strip.downcase if email.present?
		end
		# generic setting method to be used for all setters
		def set_setting(key, value)
			self.settings = settings.merge(key => value)
		end

		# unlink dependent person
		def unlink
			UserAction.prune("/users/#{id}")
			if self.person
				person&.update!(user_id: nil)
				update!(person_id: 0)	# fake person record
			end
		end
end
