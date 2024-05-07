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
# Club: manage information about sports clubs - the hosting one and rivals
#
class Club < ApplicationRecord
	before_destroy :unlink
	has_many :club_locations, dependent: :destroy
	has_many :locations, through: :club_locations
	has_many :club_sports, dependent: :destroy
	has_many :sports, through: :club_sports
	has_many :coaches
	has_many :players
	has_many :teams
	has_many :users
	has_one_attached :avatar
	pg_search_scope :search_by_any,
		against: [:nick, :name],
		ignoring: :accents,
		using: { tsearch: {prefix: true} }
	pg_search_scope :search_by_any,
		against: [:nick, :name],
		ignoring: :accents,
		using: { tsearch: {prefix: true} }
	validates :email, uniqueness: { allow_nil: true }
	validates :name, uniqueness: { allow_nil: true }
	validates :nick, presence: true
	validates :phone, uniqueness: { allow_nil: true }
#	validates :settings, uniqueness: { allow_nil: true }

	# access setting for country
	def country
		self.settings["country"].presence
	end

	# list all club events for a season
	def events
		Event.non_training.where(team_id: self.teams.pluck(:id)).order(start_time: :asc)
	end

	# access setting for country
	def locale
		self.settings["locale"].presence
	end

	# club logo
	def logo
		self.avatar.attached? ? self.avatar : "mudclub.svg"
	end

	# extended modified to account for changed avatar
	def modified?
		self.changed? || @attachment_changed
	end

	# rebuild CLub data from raw input hash given by a form submittal
	# avoids duplicate person binding
	def rebuild(f_data)
		self.address  = f_data[:address] if f_data[:address].present?
		self.email    = f_data[:email] if f_data[:email].present?
		self.name     = f_data[:name] if f_data[:name].present?
		self.nick     = f_data[:nick] if f_data[:nick].present?
		self.phone    = self.parse_phone(f_data[:phone], self.country) if f_data[:phone].present?
		self.settings["country"] = f_data["country"].presence || self.country || 'US'
		self.settings["locale"]  = f_data["locale"].presence || self.locale || 'en'
		self.settings["social"]  = f_data["social"].presence || self.social
		self.settings["website"] = f_data["website"].presence || self.website
		self.update_attachment("avatar", f_data[:avatar])
	end

	# return list of rivals for this club
	def rivals
		Club.real.where.not(id: self.id)
	end

	# access setting for country
	def social
		self.settings["social"].presence
	end

	# Just list person's full name
	def to_s
		self.name || I18n.t("club.single")
	end

	# Get collection of upcoming events for the club
	def upcoming_events
		Event.non_training.short_term.where(team_id: self.teams.pluck(:id)).order(start_time: :asc)
	end

	# access setting for country
	def website
		self.settings["website"].presence
	end

	# handle custom behaviour for creation of a club
	def self.build(f_data=nil)
		club = Club.new(settings: {})
		club.rebuild(f_data) if f_data.present?
		return club
	end

	# finds a club in the database based on id, email, name & nick
	# returns: club if it exists in the database already or
	# 	   'nil' if it not found.
	def self.fetch(f_data, create: nil)
		id    = f_data[:id].presence.to_i	# Try to find by id if present
		c_aux = Club.find_by(id:) if id > 0
		return c_aux if c_aux

		# Try to find by email if present
		c_aux = Club.find_by(email: f_data[:email]) if f_data[:email].presence

		unless c_aux	# last resort: attempt to find by name+nick
			nick = f_data[:nick].presence
			name = f_data[:name].presence
			if nick && name
				c_aux = Club.where("unaccent(nick) ILIKE unaccent(?) AND unaccent(name) ILIKE unaccent(?)", nick, name).take
			elsif nick
				c_aux = Club.where("unaccent(nick) ILIKE unaccent(?)", nick).take
			elsif name
				c_aux = Club.where("unaccent(name) ILIKE unaccent(?)", name).take
			end
		end
		return c_aux unless create
		return c_aux || Club.build(f_data)
	end

	# used to list available clubs in selectors
	def self.list
		res = [[I18n.t("status.inactive"), -1]]
		Club.real.each {|club| res << [club.nick,club.id]}
		return res
	end

	#Search field matching
	def self.search(search, user=nil)
		ucid = user&.club_id
		if search.present?
			return Club.where.not(id: [-1, ucid]).search_by_any(search).order(:nick) if user.is_manager?
			return Club.real.search_by_any(search).order(:nick) if user.admin?
		else
			return Club.where.not(id: [-1, ucid]).order(:nick) if user.is_manager?
			return Club.all.order(:nick) if user.admin?
		end
		return Club.none
	end
	
	private
		# cleanup association of dependent objects
		def unlink
			self.avatar.purge if self.avatar.attached?
			self.coaches.update_all(club_id: nil)
			self.players.update_all(club_id: nil)
			self.teams.update_all(club_id: nil)
			self.users.update_all(club_id: nil)
			UserAction.prune("/clubs/#{self.id}")
		end
end