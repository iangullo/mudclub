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
	localized_as "admissions.registration"

	#-------------------------------------
	# Class relationships
	#-------------------------------------
	belongs_to :club
	belongs_to :candidate, class_name: "AdmissionPerson"
	accepts_nested_attributes_for :candidate, reject_if: :all_blank
	belongs_to :requester, class_name: "AdmissionPerson"
	accepts_nested_attributes_for :requester, reject_if: :all_blank
	belongs_to :guardian1, class_name: "AdmissionPerson", optional: true
	accepts_nested_attributes_for :guardian1, reject_if: :all_blank
	belongs_to :guardian2, class_name: "AdmissionPerson", optional: true
	accepts_nested_attributes_for :guardian2
	belongs_to :requested_team, class_name: "Team", optional: true
	has_many :documents, dependent: :destroy
	accepts_nested_attributes_for :documents, allow_destroy: true

	has_many :messages, class_name: "RegistrationMessage",
					dependent: :destroy, inverse_of: :registration

	# used to store uploaded payment_terms files
	has_one_attached :payment_terms

	enum :status, Catalog::RegistrationStatuses.enum, prefix: true
	enum :requester_kind, Catalog::RequesterKinds.enum, prefix: true

	#-------------------------------------
	# Included Modules
	#-------------------------------------
	include Auditable
	include Kinded

	#-------------------------------------
	# Validations
	#-------------------------------------
	validates :kind, :status, :requester_kind, :club,
						:person, :requester,
						presence: true

	validate :team_required
#	validate :payment_terms_returned_when_required	# only for approve, not to create

	#-------------------------------------
	# Scopes
	#-------------------------------------
	scope :for_club, ->(club) { where(club:) }
	scope :for_team, ->(team) {	where(requested_team: team) }
	scope :pending, -> {
		where(status: %i[submitted under_review awaiting_requester])
	}
	scope :for_requester, ->(requester) {
		requester.is_a?(Person) ? where(requester:) : none
	}
	scope :for_candidate, ->(candidate) {
		candidate.is_a?(Person) ? where(candidate:) : none
	}

	#-------------------------------------
	# General API methods
	#-------------------------------------
	def different_requester
		return false unless persisted?
		return false unless requester
		candidate != requester
	end

	def person = candidate

	# registration identifier for views
	def s_name
		"##{id}"
	end

	def to_s
		persisted? ? s_name : Registration.label
	end

	# rebuild REGISTRATION data from raw input hash given by a form submittal
	# mirrors Club#rebuild to avoid duplicate person binding
	def rebuild(attrs)
		self.kind    = attrs[:kind] if attrs[:kind].present?
		self.remarks = attrs[:remarks] if attrs[:remarks].present?

		# team selection (only meaningful when the kind requires one)
		self.requested_team_id = attrs[:requested_team_id] if attrs.key?(:requested_team_id)

		# candidate — always present; delegate to AdmissionPerson#rebuild
		self.candidate = rebuild_adm_person(:candidate, attrs)
		return nil unless self.candidate

		# requester — only when the "different requester" switch is on
		self.requester = rebuild_adm_person(:requester, attrs)

		# underage
		if self.candidate.age < 18
			self.guardian1 = rebuild_adm_person(:guardian1, attrs)
			return nil unless self.guardian1

			self.guardian2 = rebuild_adm_person(:guardian2, attrs)
			self.requester = self.guardian1 unless self.requester
		else
			self.requester ||= self.candidate
		end

		# requester_kind — constrained by the kind's `requester_allowed` list
		self.requester_kind =
			case self.requester
			when self.candidate
				:self
			when self.guardian1
				:guardian
			else
				attrs[:requester_kind].present? ?
					attrs[:requester_kind].to_sym :
					:other
			end

		# payment terms return copy — attachment path, not a Document
		update_attachment("payment_terms", attrs[:payment_terms])
		self
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
		required_document_kinds.all? { |kind| documents.kind(kind).exists? }
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
			.fetch(status.to_sym)[:terminal]
	end

	def allowed_transitions
		Catalog::RegistrationStatuses
			.fetch(status.to_sym)[:transitions]
	end

	def may_transition_to?(new_status)
		allowed_transitions.include?(new_status.to_sym)
	rescue KeyError
		false
	end

	def status_label(variant = :single)
		status_key = "admissions.registration_statuses.values.#{status}.#{variant}"
		I18n.t(status_key)
	end

	private
		def payment_terms_returned_when_required
			return true unless club&.payment_terms_template
			errors.add(:payment_terms, :required) unless payment_terms.attached?
		end

		def rebuild_adm_person(adm_person, attrs)
			g_obj   = adm_person.to_sym
			g_sym   = "#{adm_person}_attributes".to_sym
			g_attrs = attrs[g_sym]

			return nil if g_attrs.blank?

			significant = g_attrs.except(:id, "id", :_destroy, "_destroy")
			return nil if significant.values.all?(&:blank?)

			g_per = self.send(g_obj) || AdmissionPerson.new
			return nil unless g_per.is_a?(AdmissionPerson)

			g_per.rebuild (g_attrs)

			g_per
		end

		def required_document_kinds
			Array(kind_catalog.fetch(kind.to_sym)[:required_documents])
		end

		def transition_to!(new_status)
			allowed = Catalog::RegistrationStatuses.fetch(status.to_sym)[:transitions]

			raise ArgumentError, "Invalid transition #{status} -> #{new_status}" \
				unless allowed.include?(new_status&.to_sym)

			yield if block_given?

			self.status = new_status.to_sym
			save!
		end

		# validate coherent team defined for assignment
		def team_required
			return unless kind_catalog.fetch(kind)[:team_required]

			errors.add(:requested_team, :blank) unless requested_team.present?
		end
end
