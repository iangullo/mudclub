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
	before_action :create_context
	around_action :switch_locale

	# check if correct  access level exists
	# works as "present AND (valid(role) OR valid(obj.condition))"
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

	# create the view's context
	def create_context
		user    = user_signed_in? ? current_user : nil
		@rdx    = p_rdx
		@season = Season.search((params[:season_id].presence)) if user
		@topbar = TopbarComponent.new(user:, home: u_path, login: new_user_session_path, logout: destroy_user_session_path)
	end

	# return FieldsComponent object from a fields array
	def create_fields(fields)
		fields ? FieldsComponent.new(fields:) : nil
	end

	# return GridComponent object from a grid hash
	def create_grid(grid, controller: nil)
		grid ? GridComponent.new(grid:, controller:) : nil
	end

	# Create a submit component
	def create_submit(close: "close", submit: "save", retlnk: nil, frame: nil)
		SubmitComponent.new(close:, submit:, retlnk:, frame:)
	end
	# ensure @season matches the calling context.
	# :obj is an object that has a :season_id link
	def get_season(obj: nil)
		return @season if @season&.id==obj&.season_id&.to_i
		@season = Season.search(obj&.season_id)
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

	def p_seasonid(base=params[:controller])
		get_param(base, :season_id)
	end
	
	def p_teamid(base=params[:controller])
		get_param(base, :team_id)
	end
	
	def p_userid(base=params[:controller])
		get_param(base, :user_id)
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

	# defines correct retlnk based on params received
	def parse_retlnk(retlnk:, valid_links:, def_path:, c_index: false)
		valid_links << u_path	# add the users path as valid destination
		if retlnk
			retlnk = (validate_link(retlnk:, valid_links:) || def_path)
		elsif u_coach? || u_manager?
			retlnk = def_path
		else
			retlnk = user_club_path
		end
		return (c_index && (retlnk == def_path)) ? "/" : retlnk
	end

	# register a new user action
	def register_action(kind, description, url: nil, modal: nil)
		u_act = UserAction.new(user_id: current_user.id, kind:, description:, url:, modal:)
		current_user.user_actions << u_act
		u_act.save
	end

	# switch app locale
	def switch_locale(&action)
		locale = (params[:locale] || current_user&.locale || I18n.default_locale)
		I18n.with_locale(locale, &action)
	end

	# wrappers to access user attributes
	def u_admin?
		current_user&.admin?
	end

	def u_manager?
		current_user&.is_manager?
	end

	def u_coach?
		current_user&.is_coach?
	end

	def u_player?
		current_user&.is_player?
	end
 
	def u_coachid
		current_user&.person.coach_id
	end

	def u_playerid
		current_user&.person.player_id
	end

	def u_personid
		current_user&.person.id
	end

	def u_userid
		current_user&.id
	end

	# wrapper to manage return links home path
	def u_path
		user_signed_in? ? user_path(current_user, rdx: 1) : "/"
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
			when Drill
				return (u_coachid==obj.coach_id)
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
				return false
			end
		end

		# get a param either from base or from a sub-node
		def get_param(base=params[:controller], key)
			(param_passed(key) || param_passed(base, key) || param_passed(base.singularize, key))
		end
			
		# Validate a link as valid input
		def validate_link(retlnk:, valid_links:)
			return nil unless retlnk.class == String
			valid_links&.include?(retlnk) ? retlnk : nil
		end
end
