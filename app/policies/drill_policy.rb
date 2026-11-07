# MudDrill - The open source Rails platform to manage amateur sports drills.
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
# app/policies/drill_policy.rb
class DrillPolicy < ApplicationPolicy
	# ---------------------------------------------------------------------------
	# Reads — global in 2.x. Any coach, any club, any drill.
	# ---------------------------------------------------------------------------
	def index?
		actor_person&.is_coach?
	end

	def show?
		actor_person&.is_coach?
	end
	alias versions? show?

	# ---------------------------------------------------------------------------
	# Writes — author or club manager
	# ---------------------------------------------------------------------------
	def create?
		allowed?(actor_person&.is_coach?)
	end
	alias new? create?

	def update?
		allowed?(@record.author_id == actor_person&.id || manages_author?)
	end
	alias edit? update?
	alias edit_diagram? update?
	alias load_diagram? update?
	alias update_diagram? update?

	def destroy?
		admin?
	end

	private

	# The acting club has a managing assignment for the actor, and the
	# drill's author is a current member of that club.
	def manages_author? = manages_person?(@record&.author)
end
