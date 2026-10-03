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
module HomeHelper
	#---------------------------------------------------------
	# fields for anonymous views
	#---------------------------------------------------------
	def home_anonymous_fields
		[
			[
				{ kind: :label, value: Clubs.label(:plural) }
			]
		]
	end

	# user login fields
	def home_closed
		[
			[
				symbol_field("user", { size: "30x30" }, align: "center"),
				button_field(home_login_button, rows: 2)
			],
			[
				{ kind: :text, value: I18n.t("status.closed"), align: "center" }
			]
		]
	end

	def home_login_button
		{ kind: "jump", url: new_user_session_path, data: { turbo_frame: "_top" }, symbol: symbol_hash("login", type: "button"), class: "m-2", d_class: "rounded bg-blue-900 hover:bg-blue-700 max-h-8 min-h-6" }
	end
end
