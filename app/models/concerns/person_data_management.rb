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
# PersonDataManagement: Module to abstract management of Person data in the
# same way for all has_one :person objects.
module PersonDataManagement
	# return whether all pics are attached
	def all_pics?
		per = self.is_a?(Person) ? self : self.person
		self.avatar.attached? && per&.id_front.attached? && per&.id_back.attached?
	end

	# Checks person is linked well
	def bind_person(save_changes: false)
		return false if self.is_a?(Person) || !self.id

		s_id = bind_field
		o_id = self.person.send(s_id).to_i
		if (o_id > 0) && (o_id != self.id)	# there's another object bound!
			self.id = o_id
			self.reload	# reload previously bound object
		end
		self.person_id    = self.person.id
		self.person[s_id] = self.id
		self.save if save_changes && self.modified?
		return true
	end

	# Check to set default values.
	def d_value(f_id)
		d_src = self.is_a?(Person) ? self.try(f_id) : self.person.try(f_id)
	end

	# Attempts to fetch a Person-related object using the hash of fields
	# received as in put. returns nil otherwise.
	def fetch_obj(f_data)
		p_cls = self.class	# object class
		p_id  = f_data[:id].to_i	# check if we already have an id
		p_obj = p_cls.find_by(id: p_id) if p_id > 0
		unless p_cls == Person or p_obj # try to fetch from person data
			s_id   = bind_field
			person = Person.fetch(f_data[:person_attributes]) if f_data[:person_attributes]
			if person.try(s_id).to_i > 0	# an obj should exist linked to this Person
				p_obj = p_cls.find_by(id: person[s_id])
			else	# the obj needs to be created
				p_obj = p_cls.new
				person ? p_obj.person = person : p_obj.build_person
			end
		end
		p_obj
	end

	# imports person data from received excel row
	# row is an array ordered as:
	# [ dni, name, surname, nick, birthday, address, email, phone, female ]
	def import_person_row(row, club=nil)
		p_data = {
			dni:      self.read_field(row[0], d_value(:dni), I18n.t("person.pid")),
			name:     self.read_field(row[1], d_value(:name), ""),
			surname:  self.read_field(row[2], d_value(:surname), ""),
			nick:     self.read_field(row[3], d_value(:nick), ""),
			birthday: self.read_field(row[4], d_value(:birthday), Date.today.to_s),
			address:	self.read_field(row[5], d_value(:address), ""),
			email:		self.read_field(row[6], d_value(:email), ""),
			phone:    self.read_field(self.parse_phone(row[7], club&.country), d_value(:phone), ""),
			female:   self.read_field(to_boolean(row[8].value), false, false)
		}
		Person.new.rebuild(p_data)
	end

	# check if Player/Coach/User (or Person) has changed
	def modified?
		res = self.id.nil? || self.changed? # object changed?
		unless (res or self.is_a?(Person))	# changes in personal data?
			res = self.person.modified?
			if self.is_a?(Player) && !res	# player parents?
				res = self.parents.any?(&:modified?)
			end
		end
		res
	end

	# required to work around for occasional glitch saving new records
	def paranoid_create
		begin
			self.save
		rescue ActiveRecord::RecordNotUnique => e
			Rails.logger.error("RecordNotUnique error: #{e.message}")
			self.save
		end
	end

	# attempt to unified rebuild Object method
	def rebuild_obj_person(f_data)
		if (p_aux = self.fetch_obj(f_data)) && (p_aux&.id != self.id)
			self.id = p_aux.id	# need to swap
			self.reload
		end
		p_data = f_data[:person_attributes]
		if p_data	# person data to be rebuilt
			p_aux = Person.fetch(p_data)
			p_aux ? self.person = p_aux : self.build_person
			self.person.rebuild(p_data)
			self.person.paranoid_create unless self.person.persisted? # Save if new person
			self.bind_person if self.person.persisted?	# ensure correct binding
		end
	end

	# get team history
	def team_list(season_id: nil)
		if season_id
			res = self.teams.where(season_id:).includes(:season).to_a
		else
			res = self.teams.includes(:season).to_a
		end
		res.sort_by { |team| team.season.start_date }.reverse
	end

	private
		# return which id_field to map against
		def bind_field
			case self
			when Coach; return :coach_id
			when Parent; return :parent_id
			when Player; return :player_id
			when User; return :user_id
			end
		end

		# scrub data from object prior to destroying
		def scrub_person(forget: nil)
			self.avatar.purge if self.try(:avatar)&.attached?
			unless self.is_a?(Person)	# need to unlink
				per = self.person
				per.update_column(bind_field, nil)
				self.update_column(:person_id, 0)
				per.destroy if forget && per&.orphan?
			end
		end
end