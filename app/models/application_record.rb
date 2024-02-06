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
class ApplicationRecord < ActiveRecord::Base
	primary_abstract_class

	# read new field value, keep old value if empty & possible
	def read_field(dat_value, old_value, def_value)
		if dat_value    # we read & assign
			case dat_value.class
			when "String"
				read_field = dat_value
			when /Roo::/	# Roo excel CELL
				read_field = dat_value.value.to_s
			else	# anything else: convert to string
				read_field = dat_value.to_s
			end
		else    # assign default if no old value exists
			read_field = def_value unless old_value
		end
	end

	# return a 2 digit string for a number
	def two_dig(num)
		num.to_s.rjust(2,'0')
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
end
