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

	before_create :assign_version_number

	#-------------------------------------
	# Class relationships
	#-------------------------------------
	belongs_to :club, optional: true
	belongs_to :person, optional: true
	belongs_to :registration, optional: true
	belongs_to :superseded_by, class_name: "Document", optional: true

	has_one_attached :file

	#-------------------------------------
	# Validations
	#-------------------------------------
	validates :kind, :status, presence: true
	validates :file, presence: true
	validate :single_owner

	#-------------------------------------
	# Included Modules
	#-------------------------------------
	include Kinded

	#-------------------------------------
	# Enum / Constants
	#-------------------------------------
	enum :status, Catalog::DocumentStatuses.enum, default: :draft, validate: true

	# target status → workflow action (bare name, no bang — it's the *name* of the
	# operation, not the predicate on the policy)
	TRANSITION_ACTIONS = {
		pending:  :submit_for_verification,
		verified: :verify,
		rejected: :reject,
		active:   :activate,
		archived: :archive
	}.freeze
	private_constant :TRANSITION_ACTIONS

	#-------------------------------------
	# Scopes
	#-------------------------------------
	scope :current, -> { active }
	scope :for_club, ->(club) { filter_by_id(:club_id, club) }
	scope :for_person, ->(person) { filter_by_id(:person_id, person) }
	scope :for_registration, ->(registration) { filter_by_id(:registration_id, registration) }

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

	#-------------------------------------
	# Kind-driven behaviour
	#-------------------------------------
	def kind_entry
		kind_catalog.fetch(kind)
	end

	def versioned?
		kind_entry.versioned?
	end

	def multi_document?
		kind_entry.multiple?
	end

	def review_required?
		kind_entry.workflow == :reviewed
	end

	def requires_acceptance?
		kind_entry.requires_acceptance?
	end

	#-------------------------------------
	# Versioning
	#-------------------------------------
	def siblings
		return self.class.none unless versioned?
		base = self.class.where(kind:)
		if    club_id.present?         then base.where(club_id:)
		elsif registration_id.present? then base.where(registration_id:)
		elsif person_id.present?       then base.where(person_id:)
		else                                self.class.none
		end
	end

	def next_version_number
		versioned? ? (siblings.maximum(:version) || 0) + 1 : 1
	end

	def latest?
		versioned? && version == siblings.maximum(:version)
	end

	#-------------------------------------
	# Status transitions
	#-------------------------------------
	def action_for(target)
		TRANSITION_ACTIONS[target.to_sym]&.to_s&.delete_suffix("!")&.to_sym
	end

	def allowed_transitions
		Catalog::DocumentStatuses.fetch(status.to_sym)[:transitions] || []
	end

	def may_transition_to?(new_status)
		allowed_transitions.include?(new_status.to_sym)
	rescue KeyError
		false
	end

	def terminal?
		Catalog::DocumentStatuses.fetch(status.to_sym)[:terminal] || false
	rescue KeyError
		false
	end

	def editable?
		Catalog::DocumentStatuses.fetch(status.to_sym)[:editable] || false
	rescue KeyError
		false
	end

	def submit_for_verification!
		transition_to!(:pending)
	end

	def verify!
		transition_to!(:verified) do
			self.verified_at ||= Time.current
		end
	end

	def reject!
		transition_to!(:rejected)
	end

	def archive!
		transition_to!(:archived)
	end

	def activate!
		transition_to!(:active) do
			# supersede siblings *inside the same transaction*
			if versioned?
				siblings.where(status: :active).where.not(id: id).find_each do |s|
					s.update!(status: :superseded,
										superseded_at: Time.current,
										superseded_by_id: id)
				end
			end
			self.activated_at  = Time.current
			self.verified_at ||= Time.current
		end
	end

	#-------------------------------------
	# Status presentation
	#-------------------------------------
	def status_label
		Catalog::DocumentStatuses.val(status.to_sym)
	end

	def status_color
		Catalog::DocumentStatuses.fetch(status.to_sym).color
	end

	#-------------------------------------
	# File handling
	#-------------------------------------
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
		def assign_version_number
			self.version = next_version_number if versioned?
		end

		def single_owner
			owners = [ club_id, registration_id, person_id ].compact
			errors.add(:base, :invalid_owner) unless owners.size == 1
		end

		def transition_to!(new_status)
			raise ArgumentError, "Invalid transition #{status} -> #{new_status}" \
				unless allowed_transitions.include?(new_status.to_sym)

			transaction do
				yield if block_given?
				self.status = new_status.to_sym
				save!
			end
		end

		def self.applies_to_for(owner)
			case owner
			when Club					then :club
			when Registration then :registration
			when Person, User then :person
			end
		end
end
