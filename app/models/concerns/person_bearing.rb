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
# app/models/concerns/person_bearing.rb
module PersonBearing
	extend ActiveSupport::Concern

	included do
		belongs_to :person
		accepts_nested_attributes_for :person
	end

	def modified?
		super || person.modified?
	end

	#------------------------------------
	# GDPR / LOPD Anonymization Orchestrator
	#------------------------------------
	def anonymize_person!
		return unless person # Guard clause if no person is attached

		self.class.transaction do
			# 1. Clear personal data attachments linked to the current execution context
			avatar.purge if respond_to?(:avatar) && avatar.attached?

			# If this context contains assignment attachments down the graph
			if respond_to?(:assignments)
				assignments.each do |assignment|
					assignment.avatar.purge if assignment.respond_to?(:avatar) && assignment.avatar.attached?
				end
			end

			# 2. Context-Specific PII Scrubbing
			case self
			when User
				# DISCONNECT: Nullify the person_id link on this User so the Person object is isolated
				# before we modify anything else.
				self.person.update!(user_id: nil)

				# Scrub login credentials and tracking data
				scrubbed_email = "deleted-user-#{id}@mudclub.local"

				update(
					email: scrubbed_email,
					encrypted_password: SecureRandom.hex(32),
					person_id: 0,
					current_sign_in_ip: nil,
					last_sign_in_ip: nil,
					reset_password_token: nil,
					settings: {} # Purge personalized configurations/preferences
				)
			when Membership
				# Membership table does not host direct string PII fields,
				# but settings metadata may store personalized attributes.
				update!(settings: {})
				# 3. Propagate down to the underlying shared Person model
				# We decouple the person's unique email to match the User's if required,
				# or set it to nil since Person allows null values.
				person.anonymize!
			end
		end
	rescue ActiveRecord::RecordInvalid => e
		Rails.logger.error "[GDPR] Bearing Anonymization failure on #{self.class.name} ##{id}: #{e.message}"
		raise e
	end

	#------------------------------------
	# Person resolution & data rebuilding
	#------------------------------------
	def resolve_person(attrs)
		return PersonResolution(status: :missing) if attrs.blank?

		resolution = Person.resolve(attrs)

		case resolution.status
		when :ambiguous
			return resolution
		when :exact, :probable
			self.person = resolution.person if resolution.person != person
		when :none
			self.person ||= Person.new
		end

		person.rebuild(attrs)

		conflicts = person.conflicts
		if conflicts.present?
			PersonResolution.new(status: :conflict, person:, conflicts:)
		else
			PersonResolution.new(status: :ok, person:, matched_by: resolution.matched_by)
		end
	end
end
