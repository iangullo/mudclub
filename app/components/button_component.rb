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
# => "remove": remove item from nested form or sortable list
# => "save": save form
# => "whatsapp": open whatsapp chat
# frozen_string_literal: true
class ButtonComponent < ApplicationComponent
	def initialize(button:)
		@button = parse(button)
	end

	def render?
		@button.present?
	end

	private

	# determine class of item depending on kind
	def parse(button)
		@button = button
		set_icon
		set_iclass
		set_bclass
		set_data
		b_colour = set_colour
		unless @button[:d_class]
			@button[:d_class] = "inline-flex align-middle"
			case @button[:kind]
			when "jump"
				@button[:d_class] = @button[:d_class] + " m-1 text-sm"
			when "location", "whatsapp"
				@button[:tab]     = true
				@button[:d_class] = @button[:d_class] + " text-sm" if @button[:icon]
			when "action", "back", "call", "cancel", "clear", "close", "edit", "email", "export", "forward", "import", "menu", "login", "save"
				b_colour = b_colour + " font-bold"
			else
				@button[:d_class] = @button[:d_class] + " font-semibold"
			end
		end
		@button[:align]   = "center" unless @button[:align]
		@button[:d_class] = @button[:d_class] + (b_colour ?  b_colour : "")
		@button
	end

	# determine class of item depending on kind
	def set_icon
		case @button[:kind]
		when "add", "add-nested"
			@button[:icon]    = "add.svg"
		when "back"
			@button[:icon]    = "back.svg"
			@button[:turbo]   = "_top"
			@button[:label]   = I18n.t("action.previous") unless @button[:label]
		when "call"
			@button[:icon]    = "phone.svg"
			@button[:url]     = "tel:#{@button[:value]}"
		when "cancel"
			@button[:icon]    = "close.svg"
			@button[:turbo]   = "_top"
		when "close"
			@button[:icon]    = "close.svg"
		when "clear"
			@button[:icon]    = "clear.svg"
			@button[:label]   = I18n.t("action.clear") unless @button[:label]
			@button[:confirm] = I18n.t("question.clear") + " \'#{@button[:name]}\'?"
		when "delete"
			@button[:turbo]   = "_top"
			@button[:icon]    = "delete.svg"
			@button[:confirm] = I18n.t("question.delete") + " \'#{@button[:name]}\'?"
		when "edit"
			@button[:icon]    = "edit.svg"
			@button[:flip]    = true
		when "email"
			@button[:icon]    = "at.svg"
			@button[:url]     = "mailto:#{@button[:value]}"
		when "export"
			@button[:icon]    = "export.svg"
			@button[:label]   = I18n.t("action.export")
			@button[:flip]    = true
		when "forward"
			@button[:icon]    = "forward.svg"
			@button[:turbo]   = "_top"
			@button[:label]   = I18n.t("action.next") unless @button[:label]
		when "import"
			@button[:icon]    = "import.svg"
			@button[:label]   = I18n.t("action.import")
			@button[:flip]    = true
			@button[:confirm] = I18n.t("question.import")
		when "jump"
			@button[:size]    = "50x50" unless @button[:size]
			@button[:turbo]   = "_top" unless @button[:turbo]
		when "remove"
			@button[:icon]    = "remove.svg"
		when "save"
			@button[:icon]    = "save.svg"
			@button[:confirm] = I18n.t("question.save_chng")
		when "whatsapp"
			@button[:icon]    = "WhatsApp.svg"
			@button[:url]     = @button[:web] ? "https://web.whatsapp.com/" : "whatsapp://"
			@button[:url]     = @button[:url] + "send?phone=#{@button[:value].delete(' ')}"
		end
		@button[:size] = "25x25" unless @button[:size]
	end

	# set the @button class depending on button type
	def set_bclass
		b_start        = @button[:b_class] ? "#{@button[:kind]}-btn " + @button[:b_class] : "#{@button[:kind]}-btn"
		@button[:name] = @button[:kind] unless @button[:name]
		case @button[:kind]
		when "remove"
			@button[:action] ||= "nested-form#remove"
		when "add", "add-nested"
			@button[:action] ||= "nested-form#add" if @button[:kind]=="add-nested"
		when "close"
			@button[:action] ||= "turbo-modal#hideModal"
			b_start = b_start + " font-bold"
		when "cancel", "clear" "save", "import", "export", "menu", "login", "back", "forward"
			b_start = b_start + " font-bold"
		end
		@button[:type]    = "submit" if @button[:kind] =~ /^(save|import|login)$/
		@button[:replace] = true if @button[:kind] =~ /^(cancel|close|save|back)$/
		@button[:b_class] = b_start + (@button[:kind]!= "jump" ? " m-1 inline-flex align-middle" : "") unless @button[:b_class]
	end

	# set the i_class for the button div
	def set_iclass
		case @button[:kind]
		when "add", "delete", "link", "location"
			@button[:i_class] = "max-h-6 min-h-4 align-middle"
		when "add-nested", "remove"
			@button[:i_class] = "max-h-5 min-h-4 align-middle"
		when  "back", "call", "cancel", "clear", "close", "edit", "email", "export", "forward", "import", "save", "whatsapp"
			@button[:i_class] = "max-h-7 min-h-5 align-middle"
		end
	end

	# set button higlight (if needed)
	def set_colour
		res = " rounded-md "
		case @button[:kind]
		when "delete", "remove", "clear", "close", "cancel"
			colour = "red"
		when "edit", "attach"
			colour = "yellow"
		when "save", "import", "export", "add", "add-nested"
			colour = "green"
		when "jump", "link", "location"
			light = "blue-100"
		when "back", "forward"
			colour = "gray"
		when "menu", "login"
			wait  = "blue-900"
			light = "blue-700"
			text  = "gray-200"
			high  = "white"
		when "action", "call", "email", "whatsapp"
			wait  = "gray-100"
			light = "gray-300"
			text  = "gray-700"
			high  = "gray-700"
		end
		if colour
			res += "hover:bg-#{colour}-200 text-#{colour}-700"
		elsif wait
			res += "bg-#{wait} text-#{text} hover:bg-#{light} hover:text-#{high} focus:bg-#{light} focus:text-#{high} focus:ring-2 focus:border-#{light}"
		else
			res += "hover:bg-#{light}"
		end
		res
	end

	# set the turbo data frame if required
	def set_data
		res = @button[:data] ? @button[:data] : {}
		res[:turbo_frame]   = @button[:frame] ? @button[:frame] : "_top"
		res[:turbo_action]  = "replace" if @button[:replace]
		res[:turbo_confirm] = @button[:confirm] if @button[:confirm]
		res[:turbo_method]  = "delete".to_sym if @button[:kind]=="delete"
		res[:action]        = @button[:action] if @button[:action]
		@button[:data]      = res unless res.empty?
	end
end
