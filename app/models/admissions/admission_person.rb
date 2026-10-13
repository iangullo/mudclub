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
class AdmissionPerson < ApplicationRecord
	localized_as "people.person"

	#-------------------------------------
	# Class relationships
	#-------------------------------------
	self.inheritance_column = "not_sti"

	#-------------------------------------
	# Included Modules
	#-------------------------------------
	include PersonData

	#-------------------------------------
	# Validations
	#-------------------------------------
	validates :name, :surname, presence: true

	#-------------------------------------
	# Object API
	#-------------------------------------

	# GDPR/LOPD compliance method - erase sensistive personal data
	def anonymize!
		return if anonymized_at.present?

		self.anonymize_data!
		update_columns(remarks: nil)
		messages.update_all(body: nil)
	end
end
