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
# BaseButton class for ButtonComponents
# conceived to serve as abstraction layer to be inherited by the
# different Button classes.
class BaseButton
	include ActionView::Helpers::TagHelper
	include ActionView::Helpers::AssetTagHelper

	# basic button information
	def initialize(button, form=nil)
		@bdata = button	# original button definition
		@form  = form
		@bdata[:name]  ||= @bdata[:kind]
		@bdata[:align] ||= "center"
		@bdata[:size]  ||= (@bdata[:kind]=="jump" ? "50x50" : "25x25")
		unless button[:b_class]
			b_start = "#{button[:kind]}-btn"
			b_start + "m-1 inline-flex align-middle" unless @kind=="jump"
		end
		# let's hold classes as arrays, it simplifies things a lot.
		@b_class = (button[:b_class] || b_start).split(" ")
		@d_class = (button[:d_class] || "inline-flex align-middle").split(" ")
	end

	# custom form setter - has to take care of the in-built objects
	def form=(formobj)
		@form = formobj
	end


	# set button higlight (if needed). returns array of classes
	def set_colour(colour: nil, wait: nil, text: nil, light: nil, high: nil)
		if colour
			res = "hover:bg-#{colour}-200 text-#{colour}-700"
		elsif wait
			res = "bg-#{wait} text-#{text} hover:bg-#{light} hover:text-#{high} focus:bg-#{light} focus:text-#{high} focus:ring-2 focus:border-#{light}"
		else
			res = "hover:bg-#{light}"
		end
		"rounded-md #{res}".split(" ")
	end

	# set the turbo data frame if required
	def set_data
		res = @bdata[:data] || {}
		res[:turbo_frame]   = @bdata[:frame] || "_top"
		res[:turbo_action]  = "replace" if @bdata[:replace]
		res[:turbo_confirm] = @bdata[:confirm] if @bdata[:confirm]
		res[:turbo_method]  = "delete".to_sym if @bdata[:kind]=="delete"
		res[:action]        = @bdata[:action] if @bdata[:action]
		@bdata[:data]       = res unless res.empty?
	end

	# A few accessor methods for data attributes
	def kind
		@bdata[:kind].presence
	end

	def icon
		@bdata[:icon].to_s
	end

	def label
		@bdata[:label].presence
	end

	def image
		image_tag(@bdata[:icon], size: @bdata[:size], class: self.i_class)
	end

	def name
		@bdata[:name].to_s
	end

	def align
		@bdata[:align].to_s
	end

	def b_class
		@b_class&.join(" ").to_s
	end

	def d_class
		@d_class&.join(" ").to_s
	end

	def i_class
		@i_class&.join(" ").to_s
	end

	def url
		@bdata[:url].presence
	end

	def confirm
		@bdata[:confirm].presence
	end

	def flip
		@bdata[:flip].presence
	end

	def size
		@bdata[:size].presence
	end

	def action
		@bdata[:action].presence
	end

	def replace
		@bdata[:replace].presence
	end

	def type
		@bdata[:type].presence
	end

	def data
		@bdata[:data].presence
	end

	def tab
		@bdata[:tab].presence
	end
end