# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
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
class Coach < ApplicationRecord
	include PersonDataManagement
	before_destroy :unlink
	belongs_to :club, optional: true
	has_many :drills
	has_and_belongs_to_many :teams
	has_one :person
	has_one_attached :avatar
	accepts_nested_attributes_for :person, update_only: true
	scope :active, -> { where.not(club_id: nil) }
	scope :real, -> { where("id>0") }
	self.inheritance_column = "not_sti"

	# returns whether the object is bound to a real club
	def active?
		self.club_id.present?
	end

	# extended modified to account for changed avatar
	def modified?
		super || @attachment_changed
	end

	def name
		self.s_name
	end

	def picture
		self.avatar.attached? ? self.avatar : self.person&.avatar&.attached? ? self.person.avatar : "coach.svg"
	end

	# rebuild Coach data from raw input hash given by a form submittal
	# avoids duplicate person binding
	def rebuild(f_data)
		self.rebuild_obj_person(f_data)
		if self.person
			self.update_attachment("avatar", f_data[:person_attributes][:avatar])
			self.club_id = f_data[:club_id].presence
		end
	end

	# short name for form viewing
	def s_name
		self.person&.s_name || I18n.t("coach.show")
	end

	# Just list person's full name
	def to_s
		self.person&.to_s || I18n.t("coach.single")
	end

	# atempt to fetch a Coach using form input hash
	def self.fetch(f_data)
		self.new.fetch_obj(f_data)
	end

	# to import from excel
	def self.import(file)
		xlsx = Roo::Excelx.new(file.tempfile)
		xlsx.each_row_streaming(offset: 1, pad_cells: true) do |row|
			if row.empty?	# stop parsing if row is empty
				return
			else
				c = self.new(active: row[7].value)
				c.import_person_row( # import personal data
					[
						row[0],	# dni
						row[2],	# name
						row[3],	# surname
						row[1],	# nick
						row[4],	# birthday
						row[5],	# address
						row[6],	# email
						row[7], # phone
						nil	# don't care on male/female tag
					]
				)
				if c.person	# only if person is bound
					c.club_id = to_boolean(row[8].value) ? clubid : nil
					c.save if c.changed?
				end
			end
		end
	end

	# Search field matching
	def self.search(search, user = nil)
		if search.present?
			if user&.is_manager? || user&.secretary?
				Coach.real.where(club_id: [ user.club_id, nil ], person_id: Person.search(search).order(:birthday))
			elsif user&.coach?
				Coach.real.where(club_id: user.club_id, person_id: Person.search(search).order(:birthday))
			else
				Coach.none
			end
		elsif user&.is_manager? || user&.secretary?
			Coach.where(club_id: user.club_id)
		else
			Coach.none
		end
	end
	private
		# cleanup association of dependent objects
		def unlink
			self.drills.update_all(coach_id: 0)
			self.teams.delete_all
			self.scrub_person
			UserAction.prune("/coaches/#{self.id}")
		end
end
