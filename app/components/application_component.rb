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
class ApplicationComponent < ViewComponent::Base
	def initialize(tag: nil, classes: nil, **options)
		@tag = tag
		@classes = classes
		@options = options
	end

	def call
		content_tag(@tag, content, class: @classes, **@options) if @tag
	end

	def tablecell_tag(item, tag=:td)
		tag(tag,
			colspan: item[:cols] ? item[:cols] : nil,
			rowspan: item[:rows] ? item[:rows] : nil,
			align: item[:align] ? item[:align] : nil,
			class: item[:class] ? item[:class] : nil
		)
	end
end
