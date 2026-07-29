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
# Catalog::Entities
#
# Defines the canonical entities recognised by MudClub.
#
class Catalog::Entities < Catalog::Base
	domain "organization"

	CATALOG = {

		club: {
			id: 10,
			namespace: :core,
			scope: :global,
			lifecycle: :immutable,
			description:
				"Sports organisation managed by MudClub."
		}
	}.freeze
end
