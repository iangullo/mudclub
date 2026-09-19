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
#
# Document
#
# Versioned documents published by a Club.
# Used during registrations, memberships and other club workflows.
#
class Document < ApplicationRecord
	localized_as "core.documents"

	#-------------------------------------
	# Class relationships
	#-------------------------------------
	belongs_to :club, optional: true
	belongs_to :person, optional: true
	belongs_to :registration, optional: true

	has_one_attached :file

	#-------------------------------------
	# Validations
	#-------------------------------------
	validates :kind, presence: true
	validates :file, presence: true
	validate :single_owner

	#-------------------------------------
	# Included Modules
	#-------------------------------------
	include Kinded

	#-------------------------------------
	# Scopes
	#-------------------------------------
	scope :active, -> { where(active: true) }
	scope :for_club, ->(club) { where(club:) }
	scope :for_person, ->(registration) { where(person:) }
	scope :for_registration, ->(registration) { where(registration:) }
	scope :current, -> { where(active: true) }

	#-------------------------------------
	# General API methods
	#-------------------------------------
	def current?
		active?
	end

	def club_document?
		club_id.present?
	end

	def person_document?
		person_id.present?
	end

	def registration_document?
		registration_id.present?
	end

	def activate!
		transaction do
			club.club_documents
					.where(kind:)
					.update_all(active: false)

			update!(active: true)
		end
	end

	def file_accept
		case file_type
		when :pdf
			"application/pdf"
		when :image
			"image/*"
		else
			nil
		end
	end

	def file_type
		kind_catalog.fetch(kind.to_sym).file_type
	end

	def self.kind_list(owner)
		kind_catalog.option_list(applies_to: applies_to_for(owner))
	end

	private
		def single_owner
			owners = [ club_id, registration_id, person_id ].compact
			errors.add(:base, :invalid_owner) unless owners.size == 1
		end

		def self.applies_to_for(owner)
			case owner
			when Club					then :club
			when Registration then :registration
			when Person, User then :person
			end
		end
end
