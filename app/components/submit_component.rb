# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2023  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
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

# SubmitComponent - ViewComponent to standardise form submissions/cancellations
class SubmitComponent < ApplicationComponent
	def initialize(close: "close", submit: nil, close_return: nil, frame: nil)
		case close
		when "close"
			b_close = {kind: "close", label: (submit=="save" ? I18n.t("action.cancel"): I18n.t("action.close")), url: close_return}
		when "cancel"
			b_close = {kind: "cancel", label: I18n.t("action.cancel"), url: close_return, frame:}
		when "back"
			b_close = {kind: "back", label: I18n.t("action.return"), url: close_return}
		end
		@close = ButtonComponent.new(button: b_close) if b_close
		if submit.class==Hash
			b_submit = submit
		elsif submit == "save" # save button
			b_submit = {kind: "save", label: I18n.t("action.save")}
		elsif submit # edit button with link in "submit"
			b_submit = {kind: "edit", label: I18n.t("action.edit"), url: submit, frame:}
		end
		@submit = ButtonComponent.new(button: b_submit) if b_submit
	end
end
