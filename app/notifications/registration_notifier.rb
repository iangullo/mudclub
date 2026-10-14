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

# app/notifications/registration_notifier.rb
module RegistrationNotifier
	RegistrationSnapshot = Data.define(
		:registration_id, :club_id, :team_id, :access_token,
		:requester, :candidate, :club, :team, :kind, :recipient
		) do
			def self.from(registration)
				new(
					registration_id: registration.id,
					club_id:         registration.club_id,
					team_id:         registration.requested_team_id,
					access_token:    registration.access_token,
					requester:       registration.requester.name,
					candidate:       registration.candidate.name,
					club:            registration.club.name,
					team:            registration.requested_team.name,
					kind:            registration.kind_label,
					recipient:       registration.requester.email.presence ||
					registration.candidate.email.presence
				)
			end

			def present? = recipient.present?
	end

	module_function
	# Capture, transition, notify. The block performs the state change
	# (which may anonymize); extras known upfront pass as keywords, extras
	# discovered inside the block return as a Hash.
	def wrap(registration, event, **preset)
		captured = capture(registration)
		result   = yield
		extras   = result.is_a?(Hash) ? preset.merge(result) : preset
		build(event, captured, **extras)&.deliver_later
	end

	def capture(registration)
		RegistrationSnapshot.from(registration)
	end

	def build(event, snapshot, **extras)
		return nil if snapshot.nil? || snapshot.recipient.blank?

		Notification.new(
			mailer: RegistrationMailer,
			event:  event,
			params: { snapshot: }.merge(extras)
		)
	end
end
