# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2023  Iván González Angullo
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
	has_one :person
	has_one_attached :avatar
	has_many :user_actions, dependent: :destroy
	scope :real, -> { where("id>0") }
	enum role: [:user, :player, :coach, :manager, :admin]
	after_initialize :set_default_role, :if => :new_record?
	accepts_nested_attributes_for :person, update_only: true
	self.inheritance_column = "not_sti"

	# locale preferences defined as enum and stored in database
	enum locale: {
		es: 0,
		en: 1
	}

	# Just list person's full name
	def to_s
		person ? person.to_s : I18n.t("user.single")
	end

	# list of possible user roles for select box configuration
	def self.role_list
		User.roles.keys.map {|role| [I18n.t("role.#{role}"),role]}
	end

	# list of possible user locales for select box configuration
	def self.locale_list
		User.locales.keys.map {|locale| [I18n.t("locale.#{locale}"),locale]}
	end

	#short name for form viewing
	def s_name
		if self.person
			if self.person.nick
				self.person.nick.length >  0 ? self.person.nick : self.person.name
			else
				self.person.name
			end
		else
			I18n.t("user.single")
		end
	end

	# return attached avatar (or default user icon)
	def picture
		self.avatar.attached? ? self.avatar : "user.svg"
	end

	#Search field matching
	def self.search(search)
		if search
			search.length>0 ? User.where(person_id: Person.where(["(id > 0) AND (name LIKE ? OR nick like ?)","%#{search}%","%#{search}%"])) : User.where(person_id: Person.real)
		else
			User.real
		end
	end

	def is_parent?
		self.person&.parent_id.to_i > 0
	end

	def is_player?
		(self.person&.player_id.to_i > 0 and self.person.player.active) or self.player?
	end

	def is_coach?
		(self.person&.coach_id.to_i > 0 and self.person.coach.active) or self.coach?
	end

	def coach
		(self.person&.coach_id.to_i > 0) ? self.person.coach : nil
	end

	def player
		(self.person&.player_id.to_i > 0) ? self.person.player : nil
	end

	def set_default_role
		self.role ||= :user
	end

	# return string with last date of user login
	def last_login
		res = self.last_sign_in_at&.to_date
		return res ? res : I18n.t("user.never")
	end

	# return last login IP
	def last_from
		self.last_sign_in_ip
	end

	# atempt to fetch a User using form input hash
	def self.fetch(f_data)
		self.new.fetch_obj(f_data)
	end

	# rebuild User data from raw input hash given by a form submittal
	# avoids duplicate person binding
	def rebuild(f_data)
		f_data[:person_attributes][:email] = f_data[:email]
		self.rebuild_obj_person(f_data)
		if self.person
			self.email                 = self.person.email
			self.role                  = f_data[:role] || :user
			self.locale                = f_data[:locale] if f_data[:locale]
			self.password              = f_data[:password] if f_data[:password]
			self.password_confirmation = f_data[:password_confirmation] if f_data[:password_confirmation]
			if self.player? and self.person.player_id.to_i==0 # need to get the player?
				self.person.player = Player.create(active: true, number: 0, person_id: self.person_id)
				self.person.player.bind_person(save_changes: true)
			end
			if self.coach? and self.person.coach_id.to_i==0 # need to create a Coach?
				self.person.coach = Coach.create(active: true, person_id: self.person_id)
				self.person.coach.bind_person(save_changes: true)
			end
		end
	end

	# get teams associated to this user
	def team_list
		c_teams = self.is_coach? ? self.coach.team_list : []
		j_teams = self.is_player? ? self.player.team_list : []
		p_teams = self.is_parent? ? self.person.parent.team_list : []
		(c_teams + j_teams + p_teams).uniq.sort_by{ |team| team.season.start_date }.reverse
	end

	private
		#unlink dependent person
		def unlink
			self.person.update(user_id: 0)
			self.avatar.purge if self.avatar.attached?
			self.person.destroy if self.person&.orphan?
		end
end
