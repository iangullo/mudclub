# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
class ApplicationRecord < ActiveRecord::Base
	include PgSearch::Model
	primary_abstract_class

	# parse phone number using defined locale as p_country
	def parse_phone(p_number, p_ctry = nil)
		ctry = p_ctry || Phonelib.default_country
		Phonelib.parse(p_number.to_s.delete(" "), ctry).international.to_s
	end

	# read new field value, keep old value if empty & possible
	def read_field(dat_value, old_value, def_value)
		if dat_value    # we read & assign
			case dat_value.class
			when "String"
				dat_value
			when /Roo::/	# Roo excel CELL
				dat_value.value.to_s
			else	# anything else: convert to string
				dat_value.to_s
			end
		else    # assign default if no old value exists
			def_value unless old_value
		end
	end

	# return a 2 digit string for a number
	def two_dig(num)
		num.to_s.rjust(2, "0")
	end

	# starting / ending hours as string
	def timeslot_string(t_begin:, t_end: nil)
		cad = two_dig(t_begin.hour) + ":" + two_dig(t_begin.min)
		cad = cad + "-" + two_dig(t_end.hour) + ":" + two_dig(t_end.min) if t_end
		cad
	end

	# parse a value to determine if its true
	def to_boolean(value)
		val = value.presence
		(val.to_s == "true" || val.to_i == 1)
	end

	# def update object attachment
	def update_attachment(field, new_file = nil)
		if self.respond_to?(field)
			attachment = self.send(field)
			if new_file
				new_blob = new_file.read
				unless new_blob == attachment&.blob # Compare blob content
					attachment.purge if attachment.attached?
					attachment.attach(new_file)
					@attachment_changed = true
				end
			end
		end
	end
end
