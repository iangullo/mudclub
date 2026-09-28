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
		manages_club?(target_club)
	end

	#------------------------------------
	# CRUD
	# Requesters (anonymous via token) —
	#  can read/act on their own registration
	#------------------------------------

	def show?    = requester_can_view? || registration_manager?
	def new?     = true
	def create?  = true
	def edit?    = requester_can_edit? || registration_manager?
	def update?  = edit?
	def destroy? = admin?

	#------------------------------------
	# Submission transitions
	#------------------------------------

	def submit?
		registration_manager? || (
			requester_can_edit? &&
			@record.may_transition_to?(:submitted)
		)
	end

	def cancel?
		registration_manager? || (
			requester_can_edit? &&
			@record.may_transition_to?(:cancelled)
		)
	end

	# Staff-only
	def approve? = registration_manager? && @record.may_transition_to?(:approved)
	def reject?  = registration_manager? && @record.may_transition_to?(:rejected)
	def review?  = registration_manager? && @record.may_transition_to?(:under_review)
	def archive? = registration_manager? && @record.may_transition_to?(:archived)

	private
		# Authenticated member with a managing club assignment.
		def registration_manager?
			return true if admin?
			return false unless actor_person && @record&.club
			manages_club?(@record.club)
		end

		def requester_is_actor_person?
			actor_person.present? &&
				@record.requester_person_id.present? &&
				@record.requester_person_id == actor_person.id
		end

		# Anonymous or member access via the requester token.
		def requester_can_view?
			token_matches?(purpose: :registration_requester) ||
				requester_is_actor_person?
		end

		def requester_can_edit?
			requester_can_view? && @record.editable_by_requester?
		end
end
