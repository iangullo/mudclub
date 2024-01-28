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
class ApplicationController < ActionController::Base
	before_action :create_topbar
	around_action :switch_locale

	# switch app locale
	def switch_locale(&action)
		locale = params[:locale] ? params[:locale] : (current_user&.locale || I18n.default_locale)
		I18n.with_locale(locale, &action)
	end

	# create the view's topbar
	def create_topbar
		@topbar = TopbarComponent.new(user: user_signed_in? ? current_user : nil, login: new_user_session_path, logout: destroy_user_session_path)
	end

	# check if correct  access level exists
	# works as "present AND (valid(role) OR valid(obj.condition))"
	def check_access(roles: nil, obj: nil)
		return (check_object(obj:) || check_role(roles:)) if current_user.present?
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
	def create_grid(grid, controller: nil)
		grid ? GridComponent.new(grid:, controller:) : nil
	end

	# Create a submit component
	def create_submit(close: "close", submit: "save", close_return: nil, frame: nil)
		SubmitComponent.new(close:, submit:, close_return:, frame:)
	end

	# register a new user action
	def register_action(kind, description, url: nil, modal: nil)
		u_act = UserAction.new(user_id: current_user.id, kind:, description:, performed_at: DateTime.now, url:, modal:)
		current_user.user_actions << u_act
		u_act.save
	end

	# wrappers to make code in all views/controllers more readable
	def u_admin?
		current_user.admin?
	end

	def u_manager?
		current_user.manager? || (current_user.admin? && current_user.is_coach?)
	end

	def u_coach?
		current_user.is_coach?
	end

	def u_player?
		current_user.is_player?
	end

	def u_coachid
		current_user.person.coach_id
	end

	def u_playerid
		current_user.person.player_id
	end

	def u_personid
		current_user.person.id
	end

	def u_userid
		current_user.id
	end

	def no_data_notice(trail: nil)
		cad = I18n.t("status.no_data")
		cad = "#{cad} (#{trail})" if trail
		helpers.flash_message(cad, "info")
	end


	# Validate a link as valid input
	def validate_link(lnk=nil, vlinks=["/"])
		return nil unless lnk.class == String
		vlinks.include?(lnk) ? lnk : nil
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
					return true  # it's a user alright
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
				return (obj.team.has_coach(u_coachid) or obj.has_player(u_playerid))
			when Person
				return (u_personid==obj.id)
			when Player
				return (u_playerid==obj.id)
			when Team
				return (obj.has_coach(u_coachid) or obj.has_player(u_playerid))
			when User
				return (u_userid==@user.id)
			else # including NilClass"
				return false
			end
		end
end
