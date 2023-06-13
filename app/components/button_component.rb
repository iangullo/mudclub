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
# ButtonComponent - ViewComponent to manage regular buttons used in views
# button is hash with following fields:
# (kind: , max_h: 6, icon: nil, label: nil, url: nil, turbo: nil)
# kinds of button:
# => "action": perform a specific controller action
# => "add": new item button
# => "add-nested": new nested-item
# => "back": go back to previous view
# => "call": make a phone call - if supported by device
# => "cancel": non-modal form cancel
# => "clear": delete a set of data
# => "close": modal close
# => "delete": delete item
# => "edit": edit link_to
# => "email": prepare  an email to somebody
# => "export": export data to excel
# => "forward": switch to next view
# => "import": import data from excel
# => "jump": jump to another view
# => "link": link to open a url in this browser window
# => "location": link to open a maps location in another browser window
# => "login": login button
# => "menu": menu button
# => "remove": remove item from nested form
# => "save": save form
# => "whatsapp": open whatsapp chat
# frozen_string_literal: true

# including the Field definitions
Dir.glob(File.expand_path('buttons/*.rb', __dir__)).each { |file| require file }

class ButtonComponent < ApplicationComponent
	attr_writer :form
	def initialize(button:, form: nil)
		@form   = form
		@button = parse(button)
	end

	def render?
		@button.present?
	end

	private
	# build right button object depending on kind
	def parse(button)
		case button[:kind]
		when "action"; ActionButton.new(button)
		when "add"; AddButton.new(button)
		when "add-nested", "remove"; NestedButton.new(button)
		when "back", "forward"; NavButton.new(button)
		when "call", "email", "whatsapp"; ContactButton.new(button)
		when "cancel", "close"; CancelButton.new(button)
		when "clear"; ClearButton.new(button)
		when "delete"; DeleteButton.new(button)
		when "edit"; EditButton.new(button)
		when "export", "import"; BulkButton.new(button)
		when "jump", "link", "location"; JumpButton.new(button)
		when "login", "menu"; MenuButton.new(button)
		when "radio", "radio-button"; RadioButton.new(button, @form)
		when "save"; SaveButton.new(button)
		when "upload", "upload-button"; UploadButton.new(button, @form)
		end
	end
end
