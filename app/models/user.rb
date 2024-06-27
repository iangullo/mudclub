# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
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
	include PersonDataManagement
	before_destroy :unlink
	# Include default devise modules. Others available are:
	# :confirmable, :lockable, :timeoutable, :registerable and :omniauthable
	devise :database_authenticatable, :recoverable,
				 :rememberable, :trackable, :validatable
	belongs_to :club, optional: true
	has_one :person
	has_one_attached :avatar
	has_many :user_actions, dependent: :destroy
	has_and_belongs_to_many :roles
	scope :real, -> { where("id>0") }
	enum role: [:user, :player, :coach, :manager, :admin]
	after_initialize :set_default_role, :if => :new_record?
	accepts_nested_attributes_for :person, update_only: true
	self.inheritance_column = "not_sti"

	def active?
		self.club_id.present?
	end

	def club_list
		res = [[I18n.t("status.inactive"), nil]]
		if self.admin?
			Club.all.each { |club| res << [club.nick, club.id]}
		else
			res << [self.club.nick ,self.club_id]
		end
		return res
	end

	def coach
		self.person.coach
	end

	# check if user has a specific role
	def has_role?(role_name)
		roles.exists?(name: role_name)
	end

	# legacy wrappers to check user role - DEPRECATED!!
	def is_coach?
		self.coach? || (self.coach&.active?)
	end

	def is_manager?
		self.manager? || (self.admin? && self.is_coach?)
	end

	def is_parent?
		!self.person.parent_id.nil?
	end

	def is_player?
		self.player? || self.player&.active?
	end

	# return last login IP
	def last_from
		self.last_sign_in_ip
	end

	# return string with last date of user login
	def last_login
		res = self.last_sign_in_at&.to_date
		return res ? res : I18n.t("user.never")
	end
	
	# wrappers for locale setting
	def locale
		settings[:locale]
	end

	def locale=(newlocale)
		set_setting(:locale, newlocale)
	end

	# extended modified to account for changed avatar
	def modified?
		super || @attachment_changed
	end

	def player
		self.person.player
	end

	# return attached avatar (or default user icon)
	def picture
		self.avatar.attached? ? self.avatar : "user.svg"
	end

	# rebuild User data from raw input hash given by a form submittal
	# avoids duplicate person binding
	def rebuild(f_data)
		f_data[:person_attributes][:email] ||= f_data[:email]
		self.rebuild_obj_person(f_data)
		if self.person
			self.club_id  = f_data[:club_id].presence
			self.email    = self.person.email
			self.role     = f_data[:role] || :user
			self.locale   = f_data[:locale] if f_data[:locale]
			self.password = f_data[:password] if f_data[:password]
			self.password_confirmation = f_data[:password_confirmation] if f_data[:password_confirmation]
			self.update_attachment("avatar", f_data[:person_attributes][:avatar])
			if self.is_player? && self.person.player_id.nil? # need to get the player?
				self.person.player = Player.create(club_id: self.club_id, number: 0, person_id: self.person_id)
				self.person.player.bind_person(save_changes: true)
			end
			if self.is_coach? && self.person.coach_id.nil? # need to create a Coach?
				self.person.coach = Coach.create(club_id: self.club_id, person_id: self.person_id)
				self.person.coach.bind_person(save_changes: true)
			end
		end
	end

	#short name for form viewing
	def s_name
		if self.person
			self.person.nick.presence || self.person.s_name
		else
			I18n.t("user.single")
		end
	end

	def set_default_role
		self.role ||= :user
	end

	# Getter method for accessing the settings hash
	def settings
		super&.symbolize_keys || {}
	end

	# Setter method for updating the settings hash
	def settings=(value)
		super(value&.to_h)
	end
	
	# get teams associated to this user
	def team_list
		c_teams = self.is_coach? ? self.coach.team_list : []
		j_teams = self.is_player? ? self.player.team_list : []
		p_teams = self.is_parent? ? self.person.parent.team_list : []
		(c_teams + j_teams + p_teams).uniq.sort_by{ |team| team.season.start_date }.reverse
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
			[I18n.t("locale.#{locale}", locale:), locale]
		end
	end

	# list of possible user roles for select box configuration
	def self.role_list
		User.roles.keys.map do |role|
			[I18n.t("role.#{role}"),role]
		end
	end

	#Search field matching
	def self.search(search, user=nil)
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
		# generic setting method to be used for all setters
		def set_setting(key, value)
			self.settings = settings.merge(key => value)
		end

		# unlink dependent person
		def unlink
			self.scrub_person
			UserAction.prune("/users/#{self.id}")
		end
end