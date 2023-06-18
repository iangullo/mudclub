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
# TextField class for FieldsComponents
# conceived to serve as abstraction layer for all labels & headers.handles
# @kinds: gap, label, side-cell, string, subtitle, title
#         and top-cell.
class TextField < BaseField
	def initialize(field)
		super(field)
		case @fdata[:kind]
		when "gap"
			@fdata[:size] ||= 4
			render_gap
		when "label"
			l_cls = "inline-flex align-top font-semibold"
			@fdata[:class] = @fdata[:class] ? @fdata[:class] + " #{l_cls}" : l_cls
		when "lines"
			@fdata[:class] ||= "align-top border px py"
    when "side-cell"
			@fdata[:align] ||= "right"
			@fdata[:class]   = "align-center font-semibold text-indigo-900"
		when "string"
			@fdata[:class]   = "align-top"
		when "subtitle"
			@fdata[:class]   = "align-top font-bold"
		when "title"
			@fdata[:class]   = "align-top font-bold text-yellow-600"
		when "top-cell"
			@fdata[:class]   = "font-semibold bg-indigo-900 text-gray-300 align-center border px py"
		end
	end

	private
	# Render a gap of several &nbsp;
	def render_gap
		@value = ""
		@fdata[:size].to_i.times { @value += "&nbsp;" }
	end
end
