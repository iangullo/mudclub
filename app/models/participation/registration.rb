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
# Registration
#
# Tracks registration to become a Club Member or an Assignment
#
class Registration < ApplicationRecord
	localized_as "participation.registration"
	include Auditable

	belongs_to :club
	belongs_to :requested_team, class_name: "Team", optional: true
	has_many :documents, dependent: :destroy

	accepts_nested_attributes_for :documents,
															allow_destroy: true

	enum :kind, Catalog::RegistrationKinds.enum, prefix: true
	enum :status, Catalog::RegistrationStatuses.enum, prefix: true
	enum :requester_kind, Catalog::RequesterKinds.enum, prefix: true

	#-------------------------------------
	# Validations
	#-------------------------------------
	validates :kind,
						:status,
						:requester_kind,
						:club,
						:candidate_name,
						:candidate_surname,
						presence: true

	validate :team_required

	#-------------------------------------
	# Scopes
	#-------------------------------------
	scope :for_club, ->(club) { where(club:) }
	scope :for_team, ->(team) {	where(requested_team: team) }
	scope :of_kind, ->(kind) { where(kind:) }
	scope :pending, -> {
		where(status: %i[submitted under_review awaiting_requester])
	}

	#-------------------------------------
	# General Assignment methods
	#-------------------------------------

	def kind_image
		Catalog::RegistrationKinds.normalize(kind) || :person
	end

	def kind_label(...)
		Catalog::RegistrationKinds.val(kind, ...)
	end

	# registration identifier for views
	def s_name
		"##{id}"
	end

	# Return person.to_s or player name and jersey number
	def to_s
		"#{candidate_name} #{candidate_surname}".presence || kind_label
	end

	#-------------------------------------
	# Workflow
	#-------------------------------------

	def submit!
		transition_to!(:submitted) do
			self.submitted_at = Time.current
		end
	end

	def begin_review!
		transition_to!(:under_review) do
			self.reviewed_at ||= Time.current
		end
	end

	def request_information!
		transition_to!(:awaiting_requester)
	end

	def approve!
		transition_to!(:approved) do
			self.reviewed_at ||= Time.current
		end
	end

	def reject!
		transition_to!(:rejected) do
			self.reviewed_at ||= Time.current
		end
	end

	def cancel!
		transition_to!(:cancelled)
	end

	def complete?
		required_document_kinds.all? do |kind|
			documents.kind(kind).exists?
		end
	end

	def modified?
		super ||
			documents.any?(&:modified?)
	end

	def editable_by_requester?
		Catalog::RegistrationStatuses
			.fetch(status.to_sym)[:editable_by_requester]
	end

	def terminal?
		Catalog::RegistrationStatuses
			.fetch(status)[:terminal]
	end

	def allowed_transitions
		Catalog::RegistrationStatuses.fetch(status)[:transitions]
	end

	def may_transition_to?(new_status)
		allowed_transitions.include?(new_status.to_sym)
	end

	# -------------------------------------------------------------------------
	# Controller façade methods
	# -------------------------------------------------------------------------

	def self.kind_image(kind)
		Catalog::RegistrationKinds.normalize(kind) || :person
	end

	def self.kind_label(kind, ...)
		Catalog::RegistrationKinds.val(kind, ...)
	end

	def self.kind_list
		Catalog::RegistrationKinds.option_list(selectable: true)
	end

	private
		def transition_to!(new_status)
			allowed = Catalog::RegistrationStatuses
									.fetch(status.to_sym)[:transitions]

			raise ArgumentError, "Invalid transition #{status} -> #{new_status}" \
				unless allowed.include?(new_status)

			yield if block_given?

			self.status = new_status
			save!
		end

		# validate coherent team defined for assignment
		def team_required
			return unless Catalog::MembershipKinds.fetch(kind)[:team_required]

			errors.add(:requested_team, :blank) unless requested_team.present?
		end
end
