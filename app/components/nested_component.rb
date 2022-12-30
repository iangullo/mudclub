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
class NestedComponent < ApplicationComponent
	def initialize(model:, key:, form:, child:, row:)
		@model   = model
		@form    = form
		@child   = child
		@key     = key
#    @fields  = nested_form_fields(fields)
		@row     = row
		@btn_add = ButtonComponent.new(button: {kind: "add-nested"})
	end

	# add remove button at end of row fields
	def nested_form_fields(fields)
		btn_del =  {kind: "remove"}
		fields.each {|item|
			item << {kind: "hidden", key: :_destroy}
			item << btn_del
		}
		fields
	end
end
