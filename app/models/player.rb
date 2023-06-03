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
class Player < ApplicationRecord
	before_destroy :unlink
	has_one :person
	has_one_attached :avatar
	has_many :stats, dependent: :destroy
	has_and_belongs_to_many :teams, dependent: :nullify
	has_and_belongs_to_many :events, dependent: :nullify
	accepts_nested_attributes_for :person, update_only: true
	accepts_nested_attributes_for :stats, reject_if: :all_blank, allow_destroy: true
	scope :real, -> { where("id>0") }
	scope :active, -> { where("active = true") }
	scope :female, -> { joins(:person).where("female = true") }
	scope :male, -> { joins(:person).where("female = false") }
	self.inheritance_column = "not_sti"
	FILTER_PARAMS = %i[search].freeze

	# Just list person's full name
	def to_s
		self.person ? self.person.to_s : I18n.t("player.single")
	end

	#short name for form viewing
	def s_name
		self.person ? self.person.s_name : I18n.t("player.single")
	end

	# String with number, name & age
	def num_name_age
		number.to_s.rjust(7," ") + "-" + self.to_s + " (" + self.person.age.to_s + ")"
	end

	def female
		self.person.female
	end

	# get attendance data for player over the period specified by "during"
	# returns attendance inthe form of:
	# matches played and session attendance [%] for week, month and season
	def attendance(team:)
		l_week   = {tot: 0, att: 0}
		l_month  = {tot: 0, att: 0}
		l_season = {tot: 0, att: 0}
		matches  = 0
		d_last7  = Date.today - 7
		d_last30 = Date.today - 30
		team.events.normal.this_season.past.each { |event|
			if event.train?
				l_season[:tot] = l_season[:tot] + 1
				l_week[:tot]   = l_week[:tot] + 1 if event.start_date > d_last7
				l_month[:tot]  = l_month[:tot] + 1 if event.start_date > d_last30
			end
			if event.players.include?(self)
				if event.match?
					matches = matches + 1
				elsif event.train?
					l_season[:att] = l_season[:att] + 1
					l_week[:att]   = l_week[:att] + 1 if event.start_date > d_last7
					l_month[:att]  = l_month[:att] + 1 if event.start_date > d_last30
				end
			end
		}
		att_week  = l_week[:tot]>0 ? (l_week[:att]*100/l_week[:tot]).to_i : nil
		att_month = l_month[:tot]>0 ? (l_month[:att]*100/l_month[:tot]).to_i : nil
		att_total = l_season[:tot]>0 ? (100*l_season[:att]/l_season[:tot]).to_i : nil
		{matches: matches, last7: att_week, last30: att_month, avg: att_total}
	end

	# check if associated person exists in database already
	# reloads person if it does
	def is_duplicate?
		if self.person.exists? # check if it exists in database
			if self.person.player_id > 0 # player already exists
				true
			else	# found but mapped to dummy placeholder person
				false
			end
		else	# not found
			false
		end
	end

	# Player picture
	def picture
		self.avatar.attached? ? self.avatar : self.person.avatar.attached? ? self.person.avatar : "player.svg"
	end

	def self.filter(filters)
		self.search(filters[:search]).order(:name)
	end

	#Search field matching
	def self.search(search)
		if search
			if search.length > 0
				Player.where(person_id: Person.where(["(id > 0) AND (unaccent(name) ILIKE unaccent(?) OR unaccent(nick) ILIKE unaccent(?) OR unaccent(surname) ILIKE unaccent(?))","%#{search}%","%#{search}%","%#{search}%"]).order(:birthday))
			else
				Player.none
			end
		else
			Player.none
		end
	end

	# to import from excel
	def self.import(file)
		xlsx = Roo::Excelx.new(file.tempfile)
		xlsx.each_row_streaming(offset: 1, pad_cells: true) do |row|
			if row.empty?	# stop parsing if row is empty
				return
			else
				j = self.new(number: row[1].value.to_s, active: row[9].value)
				j.build_person
				j.person.name = row[3].value.to_s
				j.person.surname = row[4].value.to_s
				unless j.is_duplicate? # only if not a duplicate
					if j.person.player_id == nil # new person
						j.person.coach_id  = 0
						j.person.player_id = 0
						j.person.save	# Save and link
					end
				end
				j.person.dni      = j.read_field(row[0], j.person.dni, I18n.t("person.pid"))
				j.person.nick     = j.read_field(row[2], j.person.nick, "")
				j.person.birthday = j.read_field(row[5], j.person.birthday, Date.today.to_s)
				j.person.female   = j.read_field(row[6], j.person.female, false)
				j.person.email		= j.read_field(row[7], j.person.email, "")
				j.person.phone		= j.read_field(Phonelib.parse(row[8]).international, j.person.phone, "")
				j.active	  			= j.read_field(row[9], j.active, false)
				j.save
				j.clean_bind	# ensure person is bound
			end
		end
	end

	# Is this player included in an event?
	def present?(event_id)
		self.events.include?(event_id)
	end

	# ensures a person is well bound to the player - expects both to be persisted
	def clean_bind
		self.person_id = self.person.id if self.person_id != self.person.id
		self.save if self.changed?
		self.person.bind_parent(o_class: "Player", o_id: self.id)
	end

	# rebuild Player data from raw input hash given by a form submittal
	# avoids duplicate person binding
	def rebuild(j_data)
		p_data = j_data[:person_attributes]
		if self.person_id==0 # not bound to a person yet?
			self.person = p_data[:id].to_i > 0 ? Person.find(p_data[:id].to_i) : self.build_person
		else # person is linked, get it
			self.person.reload
		end
		self.person.rebuild(p_data) # rebuild from passed data
		self.person.player_id  = self.id if self.id
		self.person.save unless self.person.id
		self.person_id = self.person.id
		self.number    = j_data[:number]
		self.active    = j_data[:active]
	end

	private
		# cleanup association of dependent objects
		def unlink
			self.person.update(player_id: 0)
			self.avatar.purge if self.avatar.attached?
		end
end
