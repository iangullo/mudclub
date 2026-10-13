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
# app/policies/registration_policy.rb
class RegistrationPolicy < ApplicationPolicy
	#------------------------------------
	# Registrations index - only managers
	#------------------------------------
	def index?
		return true if admin?
		return false unless target_club
		Server.registrations_enabled? && manages_club?(target_club)
	end

	#------------------------------------
	# CRUD
	# Requesters (anonymous via token)
	#------------------------------------

	def show?    = requester_can_view? || registration_manager?
	def new?     = Server.registrations_enabled?
	def create?  = Server.registrations_enabled?
	def edit?    = requester_can_edit? || registration_manager?
	def update?  = edit?

	#------------------------------------
	# Submission transitions
	#------------------------------------
	def send_for_review?
		registration_manager? || (
			requester_can_edit? &&
			@record.may_transition_to?(:under_review)
		)
	end

	def review?              = registration_manager? && @record.review_open?
	def request_information? = registration_manager? && @record.may_transition_to?(:awaiting_requester)
	def approve?             = registration_manager? && @record.may_transition_to?(:approved)
	def reject?              = registration_manager? && @record.may_transition_to?(:rejected)

	def cancel?
		registration_manager? || (
			requester_can_edit? &&
			@record.may_transition_to?(:cancelled)
		)
	end

	private
		# Authenticated member with a managing club assignment.
		def registration_manager?
			return true if admin?
			return false unless actor_person && @record&.club
			manages_club?(@record.club)
		end

		# TODO - needs attention since requester are not Person objects
		# 			 just AdmissionPerson ones - no way to relate to User now
		def requester_is_actor?
			actor_person.present? &&
				@record.submitted_by_id.present? &&
				@record.submitted_by_id == actor_person.id
		end

		# Anonymous or member access via the requester token.
		def requester_can_view?
			token_matches? || requester_is_actor?
		end

		def requester_can_edit?
			requester_can_view? && @record.editable_by_requester?
		end

		# Is the passed `@token` valid to access @record?
		def token_matches?
			return false unless @token && @record

			stored = @record.access_token
			return false if stored.blank?

			ActiveSupport::SecurityUtils.secure_compare(stored, @token)
		end
end
