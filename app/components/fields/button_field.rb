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
# ButtonField class for FieldsComponents
# conceived to serve as abstraction layer for all application Buttons.
# manages @kind: "button", "dropdown-button", "radio-button" and "upload-button"
class ButtonField < BaseField
	include ActionView::Helpers::TagHelper

	def initialize(field, form=nil)
		super(field, form)
		case self.kind
		when "button"
			@button = ButtonComponent.new(button: @fdata[:button], form:)
		when "contact-button"
			@button = set_contact_buttons
		when "dropdown-button"
			@button = DropdownComponent.new(button: @fdata)
		when "upload-button", "radio-button"
			@button = ButtonComponent.new(button: @fdata, form:)
		end
	end

	# custom form setter - has to take care of the in-built objects
	def form=(formobj)
		@form = formobj
		@button&.form = formobj unless self.kind == "contact-button"
	end

	def content
		@button
	end

	private
		# create the buttons for a contact form
		def set_contact_buttons
			res = []
			res << ButtonComponent.new(button: {kind: "email", value: @fdata[:email]}) if @fdata[:email]&.length > 0
			if @fdata[:phone]&.length > 0
				res << ButtonComponent.new(button: {kind: "call", value: @fdata[:phone]})
				res << ButtonComponent.new(button: {kind: "call", value: @fdata[:phone]}) if @fdata[:device] == "mobile"
				res << ButtonComponent.new(button: {kind: "whatsapp", value: @fdata[:phone], web: (@fdata[:device] == "desktop")})
			end
			res
		end
end