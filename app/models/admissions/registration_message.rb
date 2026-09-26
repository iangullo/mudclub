# MudClub - Modular Rails application for managing sports clubs.
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
# RegistrationMessage
#
# Tracks messages exchanged within a registration request
#
class RegistrationMessage < ApplicationRecord
	localized_as "admissions.registration_message"

	#-------------------------------------
	# Class relationships
	#-------------------------------------
	belongs_to :registration, inverse_of: :messages
	belongs_to :author_assignment, class_name: "Assignment", optional: true

	enum :author_kind, Catalog::RegistrationAuthorKinds.enum, prefix: true
	enum :visibility, { shared: 0, internal: 1 }, default: :shared

	#-------------------------------------
	# Validations
	#-------------------------------------
	validates :body, presence: true
	validate  :author_consistency

	#-------------------------------------
	# Scopes
	#-------------------------------------
	scope :for_requester, -> { shared }
	scope :staff_only,    -> { internal }
	scope :chronological, -> { order(:created_at) }

	#-------------------------------------
	# General API methods
	#-------------------------------------

	# Convenience for display
	def author_label
		author_assignment&.s_name || Catalog::RegistrationAuthorKinds.val(author_kind.to_sym)
	end

	private
		def author_consistency
			if author_kind_reviewer? && author_assignment.nil?
				errors.add(:author_assignment, :blank)
			elsif !author_kind_reviewer? && author_assignment.present?
				errors.add(:author_assignment, :invalid)
			end
		end
end
