# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2024  Iván González Angullo
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
class ApplicationController < ActionController::Base
	before_action :set_context
	around_action :switch_locale
	# Make these methods available to views and helpers
	helper_method :u_admin?, :u_club, :u_clubid, :u_coach?, :u_coachid,	:u_manager?,
								:u_personid, :u_player?, :u_playerid,:u_userid, :user_in_club?

	# check if correct  access level exists. Basically checks if:
	# "user is present AND (valid(role) OR valid(obj.condition))"
	# optionally, check that clubid matches.
	def check_access(roles: nil, obj: nil, both: false)
		if current_user.present?	# no access if no user logged in
			if both	# both conditions to apply
				return (check_object(obj:) && check_role(roles:))
			else	# either condition is sufficient
				return (check_object(obj:) || check_role(roles:)) 
			end
		end
		return false
	end

	# return a ButtonComponent object from a definition hash
	def create_button(button)
		button ? ButtonComponent.new(button:) : nil
	end

	# return FieldsComponent object from a fields array
	def create_fields(fields)
		fields ? FieldsComponent.new(fields:) : nil
	end

	# return GridComponent object from a grid hash
	def create_grid(grid, controller: nil, align: nil)
		grid ? GridComponent.new(grid:, controller:, align:) : nil
	end

	# prepare typical controller index page variables
	def create_index(title:, fields: nil, grid: nil, page: nil, retlnk: nil, submit: nil)
		@title  = create_fields(title)
		@fields = create_fields(fields)
		@grid   = create_grid(grid)
		@page   = page
		if (retlnk || submit)
			@submit = create_submit(close: "back", retlnk:, submit:)
		else
			@submit = create_submit(close: "close", submit: nil)
		end
	end

	# Create a submit component
	def create_submit(close: "close", submit: "save", retlnk: nil, frame: nil)
		SubmitComponent.new(close:, submit:, retlnk:, frame:)
	end

	# ensure @season matches the calling context.
	# :obj is an object that has a :season_id link
	def get_season(obj: nil)
		unless @season&.id != obj&.season_id&.to_i
			@season   = Season.search(obj&.season_id)
			@seasonid = @season&.id
		end
		return @season
	end

	# check if a string is an integer
	def is_integer(cad)
		cad.to_i.to_s == cad
	end

	# standard message for actions that had no data to change
	def no_data_notice(trail: nil)
		cad = I18n.t("status.no_data")
		cad = "#{cad} (#{trail})" if trail
		helpers.flash_message(cad, "info")
	end

	# wrappers to manage navigation routing specifiers
	# rdx (radix) arguemnt specifies base url for this view
	#		nil=>toplevel
	#		0: club/season view)
	#		1: user home view
	#		2: server logs view
	def p_rdx(base=params[:controller])
		get_param(base, :rdx)
	end
	
	def p_log(base=params[:controller])
		get_param(base, :log)
	end

	def p_clubid(base=params[:controller])
		get_param(base, :club_id, objid: true)
	end

	def p_seasonid(base=params[:controller])
		get_param(base, :season_id, objid: true)
	end
	
	def p_teamid(base=params[:controller])
		get_param(base, :team_id, objid: true)
	end
	
	def p_userid(base=params[:controller])
		get_param(base, :user_id, objid: true)
	end

	# check if some specific params are passed
	def param_passed(*keys)
		current_hash = params
		keys.each do |key|
			return nil unless current_hash[key].present?
			current_hash = current_hash[key]
		end
		return current_hash
	end

	# register a new user action
	def register_action(kind, description, url: nil, modal: nil)
		u_act = UserAction.new(user_id: current_user.id, kind:, description:, url:, modal:)
		current_user.user_actions << u_act
		u_act.save
	end

	# set the action's context
	def set_context
		if user_signed_in?
			club      = u_club
			@clubid   = get_param(:club_id, objid: true) || u_clubid
			@rdx      = p_rdx
			@season   = Season.search(p_seasonid)
			@seasonid = @season&.id
			user      = current_user
		end
		@clublogo = club&.logo || "mudclub.svg"
		@clubname = club&.nick || "MudClub"
		@favicon  = user_favicon(club)
		@topbar   = TopbarComponent.new(user:, logo: @clublogo, nick: @clubname, home: u_path, login: new_user_session_path, logout: destroy_user_session_path)
	end

	# switch app locale
	def switch_locale(&action)
		locale   = (params[:locale] || current_user&.locale || I18n.default_locale)
		I18n.with_locale(locale, &action)
	end

	# wrappers to access user attributes
	def u_admin?
		current_user&.admin?
	end

	def u_manager?
		current_user&.is_manager?
	end

	def u_club
		current_user&.club
	end

	def u_clubid
		current_user&.club_id
	end

	def u_coach?
		current_user&.is_coach?
	end
 
	def u_coachid
		current_user&.person&.coach_id
	end

	def u_personid
		current_user&.person&.id
	end

	def u_player?
		current_user&.is_player?
	end

	def u_playerid
		current_user&.person&.player_id
	end

	def u_userid
		current_user&.id
	end

	# wrapper to manage return links home path
	def u_path
		user_signed_in? ? user_path(current_user, rdx: 1) : "/"
	end

	# Check whether the user's club ID is the same as @clubid
	# @return [Boolean] - True if the current_user's club ID matches @clubid, otherwise false
	def user_in_club?
		return false unless @clubid
		@clubid == u_clubid
	end

	# check if a string is a valid date
	def valid_date(v_string)
		return nil if (d_str = v_string&.last(10))&.length != 10
		d_hash = Date._parse(d_str)
		return nil if d_hash&.size !=3
		v_date = Date.valid_date?(d_hash[:year].to_i, d_hash[:month].to_i, d_hash[:month].to_i)
		return v_date ? d_str : nil
	end

	private
		# check if current user satisfies access policy
		def check_role(roles:)
			roles&.each do |rol|	# ok as if any of roles is found
				case rol
				when :admin
					return true if u_admin?
				when :manager
					return true if u_manager?
				when :coach
					return true if u_coach?
				when :player
					return true if u_player?
				when :user
					return true if user_signed_in?  # it's a user alright
				else
					return false
				end
			end
			return false
		end

		# check object related access policy
		def check_object(obj:)
			case obj
			when Category, Division, FalseClass, Location, Season, Slot
				return true
			when Coach
				return (u_coachid==obj.id)
			when Club
				return u_admin? || (u_manager? && (obj == nil || obj.id==u_clubid))
			when Drill
				return (u_coachid==obj.coach_id) || (u_manager? && obj.coach.club_id==u_clubid)
			when Event
				return (obj.team.has_coach(u_coachid) || obj.has_player(u_playerid))
			when Person
				return (u_personid==obj.id)
			when Player
				return (u_playerid==obj.id)
			when Team
				return (obj.has_coach(u_coachid) || obj.has_player(u_playerid))
			when User
				return (u_userid==@user.id)
			else # including NilClass"
				return u_manager?
			end
		end

		# get a param either from base or from a sub-node
		def get_param(base=params[:controller], key, objid: false)
			res = (param_passed(key) || param_passed(base, key) || param_passed(base.singularize, key))
			return res unless objid
			res.nil? ? nil :  res.to_i
		end

		# Calculate pagination parameters based on available screen space or other criteria
		def paginate(data, lines=1)
			drows = case helpers.device
				when "desktop", "tablet"; 18
				when "mobile"; 15
				else; 25
			end
			per_page = (drows/lines).round
			current_page = params[:page] || 1

			data.page(current_page).per(per_page)
		end

		# determine the app favicon based on user favicon
		def user_favicon(club)
			if club&.avatar&.attached?
				url_for(club.avatar)
			else
				"mudclub.svg"
			end
		end
end
