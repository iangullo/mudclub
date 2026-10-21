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
# frozen_string_literal: true

# app/services/registration_approver.rb
class RegistrationApprover
	Result = Struct.new(:person, :membership, :assignment, :recipient_email, keyword_init: true)

	class PersonMismatch < StandardError
		attr_reader :person, :fields, :role
		def initialize(person:, fields:, role:)
			@person = person
			@fields = fields
			@role   = role
			super("Person #{person.id} does not match #{role} data in fields: #{fields.join(", ")}")
		end
	end

	def initialize(registration, actor:)
		@registration = registration
		@actor        = actor
	end

	# Pure. Returns a PersonResolution and a prepared Person.
	def prepare
		attrs      = @registration.candidate.person_attributes(include_attachments: true)
		resolution = resolve_candidate(attrs)
		prepared   = new_person_from(attrs)
		guardians  = resolve_guardians	# ← also pure, no writes
		prepared.user_id = submitter_user_id if @registration.requester_self?

		{ prepared:, resolution:, guardians: }
	end

	def commit(prepared:, guardians:, merge_with: nil)
		result = nil

		Registration.transaction do
			@registration.approve!	  # ← does NOT anonymize (see Registration#approve!)
			person = resolve_person(prepared, merge_with)

			link_guardians(person, guardians)

			membership = find_or_create_membership(person)
			assignment = find_or_create_assignment(membership)
			recipient  = notification_recipient   # BEFORE anonymize!

			@registration.anonymize!	# ← the deferred half of the approve! contract
			result = Result.new(person:, membership:, assignment:, recipient_email: recipient)
		end

		result
	end

	private
		def find_or_create_membership(person)
			Membership.find_or_create_by!(
				person:  person,
				club:    @registration.club,
				kind:    membership_kind,
				left_on: nil
			) do |m|
				m.status        = :active
				m.joined_on     = Date.current
				m.created_by_id = @actor&.id
			end
		end

		def find_or_create_assignment(membership)
			return nil unless assignment_kind

			Assignment.find_or_create_by!(
				membership: membership,
				team:       @registration.requested_team,
				kind:       assignment_kind,
				ends_on:    nil
			) do |a|
				a.status    = :active
				a.starts_on = Date.current
			end
		end

		def link_guardians(person, guardians)
			guardians.each do |g|
				merge_with = g[:resolution].ok? ? g[:resolution].person : nil
				guardian_person = resolve_person(new_person_from(g[:attrs]), merge_with)

				PersonRelationship.find_or_create_by!(
					person:         person,
					related_person: guardian_person,
					kind:           :guardian
				)
			end
		end

		def new_person_from(attrs)
			person = Person.new
			person.rebuild(attrs)
			person
		end

		def notification_recipient
			@registration.requester.email.presence ||
				@registration.candidate.email.presence
		end

		def membership_kind = registration_kind_catalog[:membership_kind]
		def assignment_kind = registration_kind_catalog[:assignment_kind]

		def registration_kind_catalog
			@registration.kind_catalog.fetch(@registration.kind.to_sym)
		end

		def resolve_person(prepared, merge_with)
			case merge_with
			when Person          then merge_with
			when String, Integer then Person.find(merge_with)
			else
				prepared.save!
				prepared
			end
		end

		def resolve_candidate(attrs)
			if @registration.requester_self? && @registration.submitted_by_id.present?
				person = @registration.submitted_by
				if person
					verify_person_matches!(attrs, person, role: :candidate)
					return PersonResolution.new(status: :exact, person:, matched_by: :submitted_by)
				end
				# submitted_by_id is set but points nowhere — treat as if not set
				# and let the resolver try to match on the candidate's own data.
				Rails.logger.warn(
					"[RegistrationApprover] submitted_by_id=#{@registration.submitted_by_id} " \
					"does not resolve for registration=#{@registration.id}"
				)
			end
			resolution = Person.resolve(attrs)
			verify_person_matches!(attrs, resolution.person, role: :candidate) if resolution.ok?
			resolution
		end

		def resolve_guardians
			return [] unless @registration.candidate.minor?

			[ @registration.guardian1, @registration.guardian2 ].compact.map do |ap|
				attrs      = ap.person_attributes(include_attachments: true)
				resolution = Person.resolve(attrs)

				if resolution.ok? && !resolution.matches?(attrs)
					Rails.logger.warn(
						"[RegistrationApprover] guardian resolve mismatch " \
						"registration=#{@registration.id} " \
						"guardian=#{ap.name} #{ap.surname} " \
						"matched_person=#{resolution.person.id} " \
						"fields=#{resolution.mismatches_against(attrs).join(",")}"
					)
				end

				{ admission_person: ap, attrs:, resolution: }
			end
		end

		def submitter_user_id = @registration.submitted_by_id

		def verify_person_matches!(attrs, person, role:)
			mismatches = PersonResolution.mismatches_against(attrs, person)

			return if mismatches.empty?

			raise PersonMismatch.new(person:, fields: mismatches, role:)
		end
end
