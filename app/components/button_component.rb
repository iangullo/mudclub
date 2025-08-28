# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
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

# ButtonComponent - ViewComponent to manage regular buttons used in views
# button is a mudsplat with following fields:
# kind:, max_h: 6, icon: nil, label: nil, url: nil, turbo: nil, title: nil (provides tooltips)
# kinds of button:
# => :action: perform a specific controller action
# => :add: new item button
# => :add_nested: new nested-item
# => :back: go back to previous view
# => :call: make a phone call - if supported by device
# => :cancel: non-modal form cancel
# => :clear: delete a set of data
# => :close: modal close
# => :delete: delete item
# => :edit: edit link_to
# => :email: prepare  an email to somebody
# => :export: export data to excel
# => :forward: switch to next view
# => :import: import data from excel
# => :jump: jump to another view
# => :link: link to open a url in this browser window
# => :location: link to open a maps location in another browser window
# => :login: login button
# => :menu: menu button
# => :remove: remove item from nested form or sortable list
# => :save: save form
# => :stimulus: trigger for stimulus action
# => :whatsapp: open whatsapp chat
# ButtonComponent - ViewComponent to manage regular buttons used in views
class ButtonComponent < ApplicationComponent
	def initialize(**attrs)
		validate(attrs)
		@button = attrs
		parse_button
	end

	# generate html content
	def call
		d_data = { controller: @button[:controller].presence }
		d_data[:processing_working] = @button[:working] if @button[:working]
		content_tag(:div, class: @button[:d_class], align: @button[:align], data: d_data, title: @button[:title]) do
			content_tag(:div, class: "relative") do
				if @button[:url]
					target = "_blank" if @button[:tab]
					link_to(@button[:url], target:, class: @button[:b_class], title: @button[:title], data: @button[:data]) do
						button_content
					end
				else
					button_tag(class: @button[:b_class], type: @button[:type], title: @button[:title], data: @button[:data]) do
						button_content
					end
				end
			end
		end
	end

	def render?
		@button.present?
	end

	private
	# label-icon content for the button
	def button_content
		c_class = "#{(@button[:kind] == :jump) ? '' : 'inline-flex '}items-center"
		content_tag(:div, class: c_class) do
			if @button[:flip]	# flip order - label first
				concat(@button[:label].presence) if @button[:label].present?
				if has_icon?
					concat("&nbsp;".html_safe) if @button[:label].present?
					concat(render_image(@button))
				end
			else
				concat(render_image(@button)) if has_icon?
				if @button[:label]
					concat("&nbsp;".html_safe) if has_icon?
					concat(@button[:label])
				end
			end
			concat(button_cue) if @button[:working]	# Processing visual cue element
		end
	rescue => e
		handle_error(e)
	end

	# define the processing cue contetn to be pushed
	def button_cue
		content_tag(:div, class: "flex rounded-md overflow-hidden w-full h-full bg-gray-300 opacity-75 absolute top-0 left-0 hidden", data: { processing_target: "processingCue" }) do
			image_tag("5-dots-fade.svg", class: "items-center align-center ml-3", title: I18n.t("status.processing"))
		end
	end

	# returns true if we ahve an icon or a symbol defined
	def has_icon?
		@button[:icon].present? || @button[:symbol].present?
	end

	# determine class of item depending on kind
	def parse_button
		hashify_symbol(@button)
		set_bclass
		set_dclass
		set_iclass
		set_data
		set_icon
		@button[:align] ||= "center"
	end

	# determine button icon depending on kind
	def set_icon
		case @button[:kind]
		when :back
			@button[:turbo]   = "_top"
		when :call
			@button[:url]     = "tel:#{@button[:value]}"
		when :cancel
			@button[:turbo]   = "_top"
		when :clear
			@button[:confirm] = I18n.t("question.clear") + " \'#{@button[:name]}\'?"
		when :delete
			@button[:turbo]   = "_top"
			@button[:confirm] = I18n.t("question.delete") + " \'#{@button[:name]}\'?"
		when :edit
			@button[:flip]    = true
		when :email
			@button[:url]     = "mailto:#{@button[:value]}"
		when :export
			@button[:flip]    = true
		when :forward
			@button[:turbo]   = "_top"
		when :import
			@button[:flip]    = true
			@button[:confirm] = I18n.t("question.import")
		when :jump
			@button[:size]  ||= "50x50"
			@button[:turbo] ||= "_top"
		when :save
			@button[:confirm] = I18n.t("question.save_chng")
		when :whatsapp
			@button[:url]  = @button[:web] ? "https://web.whatsapp.com/" : "whatsapp://"
			@button[:url] += @button[:url] + "send?phone=#{@button[:value].delete(' ')}"
		end
		@button[:label]  ||= I18n.t("action.#{@button[:kind]}") if [ :back, :cancel, :clear, :edit, :export, :import, :save ].include?(@button[:kind])
		@button[:size]   ||= "25x25"
		@button[:symbol] ||= { concept: @button[:kind].to_s, options: { type: :button } } unless @button[:icon] || @button[:kind] == :link
		if @button[:symbol]
			@button[:symbol][:options][:size] ||= @button[:size]
			@button[:symbol][:options][:css]  ||= @button[:i_class]
		end
	end

	# set the @button class depending on button type
	def set_bclass
		b_start  = "#{@button[:kind]}-btn z-40 pointer-events-auto"
		b_start += " #{@button[:b_class]}" if @button[:b_class]
		@button[:name] ||= @button[:kind].to_s
		case @button[:kind]
		when :add_nested
			@button[:action] ||= "nested-form#add"
		when :cancel, :clear, :save, :import, :export, :login, :back, :forward
			b_start += " font-bold"
		when :close
			@button[:action] ||= "turbo-modal#hideModal"
			b_start += " font-bold"
		when :remove
			@button[:action] ||= "nested-form#remove"
		when :stimulus
			@button[:type] = "button"
		end
		@button[:flip]    ||= true if [ :save, :import ].include? @button[:kind]
		@button[:title]   ||= I18n.t("action.#{@button[:kind]}") if [ :add, :add_nested, :back, :cancel, :clear, :close, :delete, :export, :forward, :import, :login, :logout, :remove, :save ].include? @button[:kind]
		@button[:type]      = "submit" if @button[:kind].to_s =~ /^(save|import|login)$/
		@button[:replace]   = true if @button[:kind].to_s =~ /^(cancel|close|save|back)$/
		@button[:b_class] ||= b_start + (@button[:kind]!= :jump ? " m-1 inline-flex align-middle" : "")
	end

	# set the buttonn d_class depending on button type
	def set_dclass
		b_colour = set_colour
		unless @button[:d_class]
			@button[:d_class] = "inline-flex align-middle"
			case @button[:kind]
			when :jump
				@button[:d_class] = @button[:d_class] + " m-1 text-sm"
				@button[:label]   = safe_join([ "<br>".html_safe, @button[:label] ]) if @button[:label]
			when :location, :whatsapp
				@button[:tab]     = true
				@button[:d_class] = @button[:d_class] + " text-sm" if has_icon?
			when :action, :back, :call, :cancel, :clear, :close, :edit, :email, :export, :forward, :import, :login, :save, :stimulus
				b_colour += " font-bold"
			else
				@button[:d_class] += " font-semibold"
			end
		end
		@button[:d_class] += b_colour if b_colour
		@button[:d_class] += " hover-div" if @button[:type] == "submit"
	end

	# set the inner css for the button div
	def set_iclass
		case @button[:kind]
		when :add, :delete, :link, :location, :stimulus
			@button[:i_class] ||= "max-h-6 min-h-4 align-middle"
		when :add_nested, :remove
			@button[:i_class] ||= "max-h-5 min-h-4 align-middle"
		when  :back, :call, :cancel, :clear, :close, :edit, :email, :export, :forward, :import, :save, :whatsapp
			@button[:i_class] ||= "max-h-7 min-h-5 align-middle"
		end
	end

	# set button higlight (if needed)
	def set_colour
		res = " rounded-md "
		case @button[:kind]
		when :delete, :remove, :clear, :close, :cancel
			colour = "red"
		when :edit, :attach
			colour = "yellow"
		when :save, :import, :export, :add, :add_nested
			colour = "green"
		when :jump, :link, :location
			light = "blue-100"
		when :back, :forward
			colour = "gray"
		when :menu, :login
			wait  = "blue-900"
			light = "blue-700"
			text  = "gray-200"
			high  = "white"
		when :action, :call, :email, :whatsapp, :stimulus
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
		if @button[:kind] == :stimulus
			res[:active_class]= "bg-blue-600 text-white ring ring-blue-300"
		else
			res[:turbo_frame] = (@button[:frame] ? @button[:frame] : "_top")
		end
		res[:turbo_action]  = "replace" if @button[:replace]
		#	res[:turbo_confirm] = @button[:confirm] if @button[:confirm] # rubocop:disable Layout/CommentIndentation
		res[:turbo_method]  = :delete.to_sym if @button[:kind]==:delete
		res[:action]        = @button[:action] if @button[:action]
		res[:confirm]       = @button[:confirm] if @button[:confirm]
		if @button[:working] || @button[:type] == "submit"
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

	# validate the button attributes received are well defined
	def validate(attrs)
		required_keys = [ :kind ] # Add other keys that are required
		required_keys << :url if [ :add, :back, :edit, :export, :delete, :forward, :jump, :link, :menu ].include?(attrs[:kind])
		required_keys.each do |key|
			unless attrs.key?(key)
				raise ArgumentError, "Button attributes are missing the required key: #{key}"
			end
		end
	end
end
