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
		[ [ label_item(Clubs.label(:plural)) ] ]
	end

	# user login fields
	def home_closed
		size = "30x30"
		[
			gap_row,
			gap_row,
			[ { kind: :title, value: I18n.t("core.application.label"), cols: 2, align: :center } ],
			[ { kind: :subtitle, value: Server.msg(:purpose_1), cols: 2, align: :center } ],
			gap_row,
			[ symbol_item(:drill, { namespace: :sport }, size:), string_item(Server.msg(:purpose_2)) ],
			[ symbol_item(:team, size:), string_item(Server.msg(:purpose_3)) ],
			[ symbol_item(:plan, size:), string_item(Server.msg(:purpose_4)) ],
			gap_row,
			gap_row,
			gap_row,
			[ home_login_button ],
			gap_row,
			gap_row
		]
	end

	def home_login_button
		normal_button({ kind: :jump, url: "/users/sign_in", data: { turbo_frame: "_top" }, symbol: symbol_hash(:login, type: :button, size: "30x30"), label: User.act(:sign_in), d_class: "rounded bg-blue-900 text-white font-semibold hover:bg-blue-700 p-1" }, cols: 2)
	end
end
