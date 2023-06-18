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
#
# NestedField class for FieldsComponents
# conceived to serve as abstraction layer for nested-form elements. Relies on
# NestedComponent.
class NestedField < AaBaseField
	def initialize(field, form=nil)
		super(field, form)
		@model   = field[:model]
		@key     = field[:key]
		@child   = field[:child]
		@row     = field[:row]
		@filter  = field[:filter]
		@btn_add = field[:btn_add] || {kind: "add-nested"}
	end

	def content
		if @form
			NestedComponent.new(model: @model, key: @key, form: @form, child: @child, row: @row, filter: @filter, btn_add: @btn_add)
		else
			"ERROR: Missing Form"
		end
	end
end