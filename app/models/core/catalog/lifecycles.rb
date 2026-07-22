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
# Catalog::Lifecycles
#
# Defines the canonical lifecycles for MudClub Core objects.
#
class Catalog::Lifecycles < Catalog::Base
	CATALOG = {

		immutable: {
			id: 0,
			description:
				"Records are permanent and may neither be archived, anonymised nor deleted."
		},

		archivable: {
			id: 10,
			description:
				"Records may become inactive while preserving their complete history."
		},

		anonymisable: {
			id: 20,
			description:
				"Personally identifiable information may be removed while preserving historical references."
		},

		disposable: {
			id: 30,
			description:
				"Records may be permanently deleted when no longer required."
		}

	}.freeze
end
