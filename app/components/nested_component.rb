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

# NestedComponent - attempt to standadise dynamic nested_form_fields as
#                   ViewComponent. NOR WORKING at the moment.
# ViewComponent to standardise nested forms
# row: is passed ass path to partial for each element to be rendered
class NestedComponent < ApplicationComponent
	def initialize(model:, key:, form:, child:, row:, newline: true, btn_add: {kind: "add-nested"})
		@model   = model
		@form    = form
		@child   = child
		@key     = key
		@row     = row
		@btn_del = ButtonComponent.new(button: {kind: "remove"})
		@btn_add = ButtonComponent.new(button: btn_add) if  btn_add
	end
end
