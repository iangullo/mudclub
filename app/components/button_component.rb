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
    validate(button)
		@button = button
		parse(button)
	end

=begin
	# generate html content
	def call
		d_data = {controller: @button[:controller].presence}
		d_data[:processing_working] = @button[:working].html_safe if @button[:working]
		content_tag(:div, class: @button[:d_class], align: @button[:align], d_data:) do
			content_tag(:div, class: "relative") do
				if @button[:url]
					target = @button[:tab] ? "_blank" : nil
					link_to(@button[:url], target:, class: @button[:b_class], data: @button[:data]) do
						button_content
					end
				else
					button_tag(class: @button[:b_class], type: @button[:type], data: @button[:data]) do
						button_content
					end
				end
				button_cue if @button[:working] #Processing visual cue element
			end
		end
	end
=end

	def render?
		@button.present?
	end

	private
	# label-icon content for the button
	def button_content
		c_class = "#{(@button[:kind] == "jump") ? '' : 'inline-flex '}items-center"
		content_tag(:div, class: c_class) do
			if @button[:flip]	# flip order - label first
				concat(@button[:label]) if @button[:label]
				if @button[:icon]
					concat("&nbsp;".html_safe) if @button[:label]
					concat(image_tag(@button[:icon], size: @button[:size], class: @button[:i_class]))
				end
			else
				concat(image_tag(@button[:icon], size: @button[:size], class: @button[:i_class])) if @button[:icon]
				if @button[:label]
					concat("&nbsp;".html_safe) if @button[:icon]
					concat(@button[:label])	
				end
			end
		end
	rescue => e
		handle_error(e)
	end

	# define the processing cue contetn to be pushed
	def button_cue
		content_tag(:div, class: "flex rounded-md overflow-hidden w-full h-full bg-gray-300 opacity-75 absolute top-0 left-0 hidden", data: { processing_target: "processingCue" }) do
			image_tag('5-dots-fade.svg', class: "items-center align-center ml-3")
		end
	end

	# determine class of item depending on kind
	def parse(button)
		set_icon
		set_bclass
		set_dclass
		set_iclass
		set_data
		@button[:align] ||= "center"
	end

	# determine class of item depending on kind
	def set_icon
		case @button[:kind]
		when "add", "add-nested"
			@button[:icon]  ||= "add.svg"
		when "back"
			@button[:icon]  ||= "back.svg"
			@button[:turbo]   = "_top"
			@button[:label] ||= I18n.t("action.previous")
		when "call"
			@button[:icon]  ||= "phone.svg"
			@button[:url]     = "tel:#{@button[:value]}"
		when "cancel"
			@button[:icon]  ||= "close.svg"
			@button[:turbo]   = "_top"
		when "close"
			@button[:icon]  ||= "close.svg"
		when "clear"
			@button[:icon]  ||= "clear.svg"
			@button[:label] ||= I18n.t("action.clear")
			@button[:confirm] = I18n.t("question.clear") + " \'#{@button[:name]}\'?"
		when "delete"
			@button[:icon]  ||= "delete.svg"
			@button[:turbo]   = "_top"
			@button[:confirm] = I18n.t("question.delete") + " \'#{@button[:name]}\'?"
		when "edit"
			@button[:icon]  ||= "edit.svg"
			@button[:flip]    = true
		when "email"
			@button[:icon]  ||= "at.svg"
			@button[:url]     = "mailto:#{@button[:value]}"
		when "export"
			@button[:icon]  ||= "export.svg"
			@button[:label]   = I18n.t("action.export")
			@button[:flip]    = true
		when "forward"
			@button[:icon]  ||= "forward.svg"
			@button[:turbo]   = "_top"
			@button[:label] ||= I18n.t("action.next")
		when "import"
			@button[:icon]  ||= "import.svg"
			@button[:label]   = I18n.t("action.import")
			@button[:flip]    = true
			@button[:confirm] = I18n.t("question.import")
		when "jump"
			@button[:size]    = "50x50" unless @button[:size]
			@button[:turbo]   = "_top" unless @button[:turbo]
		when "remove"
			@button[:icon]  ||= "remove.svg"
		when "save"
			@button[:icon]  ||= "save.svg"
			@button[:confirm] = I18n.t("question.save_chng")
		when "whatsapp"
			@button[:icon]  ||= "WhatsApp.svg"
			@button[:url]     = @button[:web] ? "https://web.whatsapp.com/" : "whatsapp://"
			@button[:url]     = @button[:url] + "send?phone=#{@button[:value].delete(' ')}"
		end
		@button[:size] = "25x25" unless @button[:size]
	end

	# set the @button class depending on button type
	def set_bclass
		b_start          = @button[:b_class] ? "#{@button[:kind]}-btn " + @button[:b_class] : "#{@button[:kind]}-btn"
		@button[:name] ||= @button[:kind]
		case @button[:kind]
		when "add", "add-nested"
			@button[:action] ||= "nested-form#add" if @button[:kind]=="add-nested"
		when "cancel", "clear" "save", "import", "export", "login", "back", "forward"
			b_start += " font-bold"
		when "close"
			@button[:action] ||= "turbo-modal#hideModal"
			b_start += " font-bold"
		when "remove"
			@button[:action] ||= "nested-form#remove"
		end
		@button[:flip]     ||= true if ["save","import"].include? @button[:kind]
		@button[:type]       = "submit" if @button[:kind] =~ /^(save|import|login)$/
		@button[:replace]    = true if @button[:kind] =~ /^(cancel|close|save|back)$/
		@button[:b_class]  ||= b_start + (@button[:kind]!= "jump" ? " m-1 inline-flex align-middle" : "")
	end

	# set the buttonn d_class depending on button type
	def set_dclass
		b_colour = set_colour
		unless @button[:d_class]
			@button[:d_class] = "inline-flex align-middle"
			case @button[:kind]
			when "jump"
				@button[:d_class] = @button[:d_class] + " m-1 text-sm"
			when "location", "whatsapp"
				@button[:tab]     = true
				@button[:d_class] = @button[:d_class] + " text-sm" if @button[:icon]
			when "action", "back", "call", "cancel", "clear", "close", "edit", "email", "export", "forward", "import", "login", "save"
				b_colour += " font-bold"
			else
				@button[:d_class] += " font-semibold"
			end
		end
		@button[:d_class] += b_colour if b_colour
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
#		res[:turbo_confirm] = @button[:confirm] if @button[:confirm]
		res[:turbo_method]  = "delete".to_sym if @button[:kind]=="delete"
		res[:action]        = @button[:action] if @button[:action]
		res[:confirm]       = @button[:confirm] if @button[:confirm]
		if (@button[:working] || @button[:type] == "submit")
			unless @button[:working] == false
				@button[:controller] = "processing"
				@button[:working]  ||= true
				res[:action]         = "processing#submit"
			end
		else
			res[:controller]  = @button[:controller] if @button[:controller]
		end
		@button[:data]      = res unless res.empty?
	end

	# validate the button hash received is well defined
	def validate(button)
		required_keys = [:kind] # Add other keys that are required
		required_keys << :url if ["add", "back", "edit", "export", "delete", "forward", "jump", "link", "menu"].include?(button[:kind])
		required_keys.each do |key|
			unless button.key?(key)
				raise ArgumentError, "Button hash is missing the required key: #{key}"
			end	
		end
	end
end
