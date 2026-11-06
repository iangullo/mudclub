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

# ModalComponent - minimal standard ViewComponent for Modal views
class ModalComponent < ApplicationComponent
	# Chrome around the card, in rem:
	#   top-10 (2.5) + m-2 top (0.5) + m-2 bottom (0.5)
	# Keep in sync with the Tailwind classes on the card in the template.
	CHROME_REM = 3.5

	def initialize(simple: nil, height: nil, width: "90%")
		@width  = width
		h_cap   = "calc(100dvh - #{CHROME_REM}rem)"
		@height = height ? "min(#{height}, #{h_cap})" : h_cap
		@close  = ButtonComponent.new(kind: :close, label: I18n.t("action.close")) if simple
	end
end
